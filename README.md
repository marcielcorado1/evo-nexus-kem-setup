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
sed -i 's/dangerouslySkipPermissions ? {/(dangerouslySkipPermissions || process.env.CLAUDE_DANGEROUSLY_SKIP_PERMISSIONS === ''1'') ? {/g' "$BRIDGE" && \
echo "✅ Fix aplicado em: $BRIDGE"
```

Abra uma nova sessão no Terminal — o fix entra em vigor imediatamente.

> 💡 **Contexto**: o NEXCORE roda como root dentro do Docker. Versões mais recentes da imagem já incluem este fix nativamente — o comando acima é necessário apenas se o terminal não responder após o deploy.

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

**v0.33.0-nexcore-kem.1**
