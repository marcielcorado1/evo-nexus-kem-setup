FROM evoapicloud/evo-nexus-dashboard:v0.33.0

# Terminal bypass fix — permite usar --dangerously-skip-permissions em Docker
# Modificação: converte a flag em variável de ambiente
COPY patches/claude-bridge.js /workspace/dashboard/terminal-server/src/claude-bridge.js

# Garante permissões de execução
RUN chmod +x /workspace/dashboard/terminal-server/src/claude-bridge.js

# Labels para rastreabilidade
LABEL maintainer="Kem Soluções"
LABEL version="v0.33.0-kem-ready.1"
LABEL description="EvoNexus pré-configurado para Kem Soluções"
