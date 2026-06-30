# 🚀 NEXCORE Kem Setup

Deploy do NEXCORE em minutos via Coolify.

---

## ⚡ Como Instalar no Coolify (Web UI)

### Passo 1 — Abrir o repositório

Acesse `github.com/marcielcorado1/nexcore-kem-setup`, clique no arquivo `docker-compose-student.yml` → botão **Raw** → copie todo o conteúdo (Ctrl+A → Ctrl+C).

### Passo 2 — Criar o recurso no Coolify

No Coolify: **Projects** → **New Project** → nome "NEXCORE" → **New Resource** → **Docker Compose (Empty)**.

### Passo 3 — Colar e configurar o domínio

Cole o YAML no campo de conteúdo. Localize as **4 ocorrências** de `nexcore.seudominio.com.br` e substitua pelo seu domínio real.

### Passo 4 — Adicionar a chave da IA

Na aba **Environment Variables**, adicione:

```
ANTHROPIC_API_KEY = sk-ant-...
```

> ⚠️ **Atenção**: Esta é a única variável obrigatória antes do primeiro deploy.  
> Todas as outras credenciais (GitHub, Vercel, Supabase, etc.) são configuradas depois via `/sync-env`.

### Passo 5 — Deploy

Clique em **Save** e depois **Deploy**. Aguarde 2-3 minutos até os 4 containers ficarem **healthy**.

### Passo 6 — Pronto! ✅

```
https://nexcore.seudominio.com.br
```

---

## 🔧 Pós-Deploy — Verificar Terminal

Após o deploy, abra o Terminal integrado do NEXCORE e execute:

```bash
claude --version
```

**Resultado esperado:** retorna a versão do Claude Code (ex: `1.x.x`). Terminal funcionando, nenhuma ação necessária.

**Se o terminal travar ou recusar a execução** (erro relacionado a permissões root no Docker), rode o comando abaixo — ele aplica o fix diretamente no container, sem reiniciar nada:

```bash
BRIDGE=$(find / -name "claude-bridge.js" 2>/dev/null | head -1) && \
sed -i 's/dangerouslySkipPermissions ? {/(dangerouslySkipPermissions || process.env.CLAUDE_DANGEROUSLY_SKIP_PERMISSIONS === '1') ? {/g' "$BRIDGE" && \
echo "✅ Fix aplicado em: $BRIDGE"
```

Abra uma nova sessão no Terminal — o fix entra em vigor imediatamente.

> 💡 **Contexto**: o NEXCORE roda como root dentro do Docker. Versões mais recentes da imagem já incluem este fix nativamente — o comando acima é necessário apenas se o terminal não responder após o deploy.

---

## 🔧 Pós-Deploy — Fix Social Auth (container não inicia)

O container `nexcore_social_auth` depende de um arquivo que **não é criado automaticamente pelo onboarding**. Se ele ficar em loop de restart, siga os passos abaixo.

### Passo 1 — Abra o terminal do NEXCORE

```
https://nexcore.seudominio.com.br/terminal
```

### Passo 2 — Crie a pasta e o arquivo (cole tudo de uma vez)

```bash
mkdir -p /workspace/workspace/social && cat > /workspace/workspace/social/start-social-auth.py << 'PYEOF'
"""
Launcher do Evolution Social Auth.
"""
import sys
import os
import secrets as _sec
import urllib.parse as _urlparse
import urllib.request
import urllib.error
import json
import time
import fcntl
import re as _re

sys.path.insert(0, "/workspace/social-auth")
os.chdir("/workspace/social-auth")

from app import app  # noqa: E402

_PREFIX = "/social-auth"

try:
    _env_path = "/workspace/config/.env"
    if not os.path.exists(_env_path):
        _env_path = "/workspace/.env"
    _env_vars = {}
    with open(_env_path) as _f:
        for line in _f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, _, v = line.partition("=")
                _env_vars[k.strip()] = v.strip()
    _secret = _env_vars.get("EVONEXUS_SECRET_KEY") or _env_vars.get("DASHBOARD_API_TOKEN")
    if _secret:
        app.secret_key = _secret
except Exception:
    pass

@app.after_request
def _fix_prefix(response):
    if response.status_code in (301, 302, 303, 307, 308):
        loc = response.headers.get("Location", "")
        if loc.startswith("/") and not loc.startswith(_PREFIX):
            response.headers["Location"] = _PREFIX + loc
    if response.content_type and "html" in response.content_type:
        html = response.get_data(as_text=True)
        html = _re.sub(
            r'(href|action|src)="(/(?!social-auth)[^"]*)"',
            lambda m: f'{m.group(1)}="{_PREFIX}{m.group(2)}"',
            html,
        )
        response.set_data(html)
    return response

_STATES_FILE = "/workspace/config/.oauth_states.json"
_STATE_TTL = 600

def _load_states() -> dict:
    try:
        with open(_STATES_FILE) as f:
            return json.load(f)
    except Exception:
        return {}

def _save_states(states: dict):
    tmp = _STATES_FILE + ".tmp"
    with open(tmp, "w") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        json.dump(states, f)
        fcntl.flock(f, fcntl.LOCK_UN)
    os.replace(tmp, _STATES_FILE)

def _add_state(state: str):
    states = _load_states()
    now = time.time()
    states = {k: v for k, v in states.items() if now - v < _STATE_TTL}
    states[state] = now
    _save_states(states)

def _consume_state(state: str) -> bool:
    states = _load_states()
    now = time.time()
    states = {k: v for k, v in states.items() if now - v < _STATE_TTL}
    if state not in states:
        _save_states(states)
        return False
    del states[state]
    _save_states(states)
    return True

def _redirect_uri() -> str:
    from env_manager import read_env
    env = read_env()
    ngrok = env.get("NGROK_URL", "").rstrip("/")
    if ngrok:
        return ngrok + "/callback/youtube"
    from flask import request
    return request.host_url.rstrip("/") + _PREFIX + "/callback/youtube"

def _youtube_oauth_start():
    from flask import redirect
    from env_manager import read_env
    env = read_env()
    client_id = env.get("YOUTUBE_OAUTH_CLIENT_ID", "")
    if not client_id:
        return "YOUTUBE_OAUTH_CLIENT_ID not configured", 400
    state = _sec.token_urlsafe(32)
    _add_state(state)
    params = _urlparse.urlencode({
        "client_id": client_id,
        "redirect_uri": _redirect_uri(),
        "response_type": "code",
        "scope": "https://www.googleapis.com/auth/youtube https://www.googleapis.com/auth/youtube.force-ssl https://www.googleapis.com/auth/yt-analytics.readonly",
        "access_type": "offline",
        "state": state,
        "prompt": "consent",
    })
    return redirect(f"https://accounts.google.com/o/oauth2/v2/auth?{params}")

def _youtube_callback():
    from flask import request, redirect
    from env_manager import read_env, save_account, next_index
    env = read_env()
    state = request.args.get("state", "")
    if not _consume_state(state):
        return (
            f"<h3>Invalid state</h3><p><a href='{_PREFIX}/connect/youtube/oauth'>Tentar novamente</a></p>",
            403,
        )
    code = request.args.get("code", "")
    if not code:
        return f"Error: {request.args.get('error', 'no code')}", 400
    data = _urlparse.urlencode({
        "code": code,
        "client_id": env.get("YOUTUBE_OAUTH_CLIENT_ID", ""),
        "client_secret": env.get("YOUTUBE_OAUTH_CLIENT_SECRET", ""),
        "redirect_uri": _redirect_uri(),
        "grant_type": "authorization_code",
    }).encode()
    req = urllib.request.Request(
        "https://oauth2.googleapis.com/token", data=data, method="POST",
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    try:
        with urllib.request.urlopen(req) as resp:
            token_data = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        return f"Token exchange failed: {e.read().decode()}", 500
    access_token = token_data.get("access_token", "")
    refresh_token = token_data.get("refresh_token", "")
    channel_name = "YouTube"
    channel_id = ""
    try:
        url = f"https://www.googleapis.com/youtube/v3/channels?part=snippet,statistics&mine=true&access_token={access_token}"
        with urllib.request.urlopen(url) as resp:
            channels = json.loads(resp.read())
        if channels.get("items"):
            ch = channels["items"][0]
            channel_name = ch["snippet"]["title"]
            channel_id = ch["id"]
    except Exception:
        pass
    idx = next_index("youtube")
    fields = {"ACCESS_TOKEN": access_token, "CHANNEL_ID": channel_id}
    if refresh_token:
        fields["REFRESH_TOKEN"] = refresh_token
    save_account("youtube", idx, channel_name, fields)
    return redirect(f"/?saved=YouTube ({channel_name})")

app.view_functions["youtube.oauth_start"] = _youtube_oauth_start
app.view_functions["youtube.callback"] = _youtube_callback

port = int(os.environ.get("SOCIAL_AUTH_PORT", 8765))
print(f"  Evolution Social Auth — 0.0.0.0:{port}")
app.run(host="0.0.0.0", port=port, debug=False)
PYEOF
```

### Passo 3 — Confirme que o arquivo foi criado

```bash
ls -la /workspace/workspace/social/
```

> Deve aparecer `start-social-auth.py` com tamanho maior que zero.

### Passo 4 — Reinicie o container no Coolify

Coolify → recurso NEXCORE → container **nexcore_social_auth** → **Restart**.

Aguarde 30 segundos. O container deve ficar verde (Running).

> **Por que isso acontece:** o volume `nexcore_workspace` começa vazio em cada instalação nova. O onboarding cria o `scheduler-startup.sh` mas não o `start-social-auth.py`. Este fix é necessário apenas uma vez por instalação.

---

## 📦 O Que Você Ganha

| Item | Quantidade |
|---|---|
| Agentes de IA | 38 (Clawdia, Flux, Atlas, Oracle, Pulse, Sage, Pixel, etc.) |
| Skills de automação | 175+ |
| Volumes persistentes | 16 (dados não se perdem em updates) |
| SSL automático | ✅ (Let's Encrypt via Traefik) |
| Containers | 4 (dashboard, social_auth, telegram, scheduler) |

---

## 🔄 Como Atualizar

Quando houver nova versão do NEXCORE:

1. Copie o novo `docker-compose-student.yml` deste repositório
2. Cole no Coolify → **Save & Redeploy**
3. Seus dados persistem automaticamente (volumes Docker)

---

## 🆘 Problemas Comuns

| Problema | Solução |
|---|---|
| `Network 'coolify' not found` | No servidor: `docker network create coolify` |
| Site não abre (503) | Verifique se o DNS já propagou para o IP da VPS |
| Site não abre (DNS) | Confirme que o registro A aponta para o IP correto |
| Dashboard abre mas IA não responde | Configure `ANTHROPIC_API_KEY` na aba Environment Variables |
| Scheduler em loop de restart | Normal até configurar a `ANTHROPIC_API_KEY` |
| Erro 4 ocorrências de domínio | Verifique se substituiu `nexcore.seudominio.com.br` nos 4 lugares |
| Terminal trava (erro root/Docker) | Execute o comando de fix na seção "Pós-Deploy — Verificar Terminal" |
| `nexcore_social_auth` em loop de restart | Siga a seção "Fix Social Auth" acima |

---

## 📚 O Que é NEXCORE?

NEXCORE é uma plataforma de **IA + Automação** com:

- **38 agentes especializados** (operações, finanças, marketing, CS, engenharia, etc.)
- **Agentes proativos** que trabalham no horário agendado sem você pedir
- **175+ skills** de automação prontas para usar
- **Memória persistente** entre sessões — os agentes lembram do contexto
- **Integrações** com Discord, Telegram, Stripe, GitHub, Linear, Omie, etc.

Baseado no [EvoNexus](https://github.com/EvolutionAPI/evo-nexus) (open source).

---

**v0.33.0-nexcore-kem.2**
