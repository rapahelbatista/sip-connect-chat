#!/bin/bash
# ================================================================
# CENTRAL DE COMUNICAÇÃO - Script de Instalação VPS
# Asterisk 20 (WebRTC) + Evolution API (WhatsApp)
# Compatível com Ubuntu 22.04 / 24.04
# ================================================================
# USO: chmod +x install.sh && sudo ./install.sh
# Para recomeçar do zero: sudo ./install.sh --reset
# Verificar status dos serviços: sudo ./install.sh --status
# ================================================================

# ---- CONFIGURAÇÕES (EDITE ANTES DE EXECUTAR) ----
DOMAIN="seu-dominio.com"           # Domínio do VPS (ou IP público)
ASTERISK_AMI_USER="admin"          # Usuário AMI do Asterisk
ASTERISK_AMI_PASS="SuaSenhaForte123!"  # Senha AMI
WEBRTC_CERT_EMAIL="seu@email.com"  # Email para certificado SSL
EVOLUTION_API_KEY="sua-chave-api"  # Chave da Evolution API
POSTGRES_DB="evolution"            # Nome do banco PostgreSQL
POSTGRES_USER="evolution"          # Usuário PostgreSQL
GIT_REPO=""                        # URL do repositório Git do painel (ex: https://github.com/user/repo.git)
GIT_TOKEN=""                       # Token de acesso pessoal do GitHub (para repos privados)

# ---- ARQUIVO DE ESTADO (checkpoint) ----
STATE_FILE="/opt/.central-install-state"
VARS_FILE="/opt/.central-install-vars"

# Cores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

# ---- VERIFICAÇÃO DE ROOT ----
if [ "$(id -u)" -ne 0 ]; then
  err "Este script deve ser executado como root (sudo ./install.sh)"
fi

# ---- RESET ----
if [ "$1" = "--reset" ]; then
  rm -f "$STATE_FILE" "$VARS_FILE"
  log "Estado resetado. Execute novamente sem --reset."
  exit 0
fi

# ---- STATUS ----
if [ "$1" = "--status" ]; then
  echo ""
  echo "=================================================="
  echo -e "${CYAN}  STATUS DOS SERVIÇOS${NC}"
  echo "=================================================="
  echo ""

  check_service() {
    local name=$1
    local svc=$2
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
      echo -e "  ${GREEN}● ${name}${NC} — ativo (running)"
    else
      echo -e "  ${RED}● ${name}${NC} — inativo/parado"
    fi
  }

  check_service "Asterisk" "asterisk"
  check_service "Nginx" "nginx"
  check_service "PostgreSQL" "postgresql"
  check_service "Evolution API" "evolution-api"

  echo ""
  echo -e "  ${CYAN}Portas em uso:${NC}"
  echo "  ──────────────────────────────────"
  for port in 80 443 5060 8080 8089 5432; do
    PROC=$(ss -tlnp "sport = :$port" 2>/dev/null | tail -n +2 | awk '{print $4, $6}' | head -1)
    if [ -n "$PROC" ]; then
      echo -e "    ${GREEN}:${port}${NC}  $PROC"
    else
      echo -e "    ${YELLOW}:${port}${NC}  (livre)"
    fi
  done

  echo ""
  echo -e "  ${CYAN}Disco:${NC}"
  df -h / | tail -1 | awk '{printf "    Usado: %s / %s (%s)\n", $3, $2, $5}'

  echo ""
  echo -e "  ${CYAN}Memória:${NC}"
  free -h | grep Mem | awk '{printf "    Usada: %s / %s\n", $3, $2}'

  echo ""
  if [ -f "$STATE_FILE" ]; then
    echo -e "  ${CYAN}Etapas de instalação:${NC}"
    while IFS= read -r step; do
      echo -e "    ${GREEN}✓${NC} $step"
    done < "$STATE_FILE"
  else
    echo -e "  ${YELLOW}Nenhuma instalação registrada${NC}"
  fi

  echo ""
  echo "=================================================="
  exit 0
fi

# ---- FUNÇÕES DE CHECKPOINT ----
step_done() {
  grep -qxF "$1" "$STATE_FILE" 2>/dev/null
}

mark_done() {
  echo "$1" >> "$STATE_FILE"
  log "Etapa '$1' concluída ✓"
}

save_var() {
  touch "$VARS_FILE"
  sed -i "/^$1=/d" "$VARS_FILE" 2>/dev/null || true
  echo "$1=$2" >> "$VARS_FILE"
}

load_vars() {
  if [ -f "$VARS_FILE" ]; then
    source "$VARS_FILE"
  fi
}

# Executa comando e aborta a etapa se falhar
run() {
  if ! "$@"; then
    warn "Comando falhou: $*"
    warn "Re-execute o script para tentar novamente esta etapa."
    exit 1
  fi
}

# ---- CARREGAR VARIÁVEIS ANTERIORES ----
load_vars

# Gerar senha do PostgreSQL apenas na primeira execução (só alfanuméricos para evitar problemas)
if [ -z "$POSTGRES_PASS" ]; then
  POSTGRES_PASS="EvoPass$(openssl rand -hex 8)"
  save_var "POSTGRES_PASS" "$POSTGRES_PASS"
fi

# ---- VALIDAR CONFIGURAÇÕES ----
validate_config() {
  local errors=0

  if [ "$DOMAIN" = "seu-dominio.com" ]; then
    warn "DOMAIN não foi configurado! Edite o topo do script."
    errors=$((errors + 1))
  fi

  if [ "$WEBRTC_CERT_EMAIL" = "seu@email.com" ]; then
    warn "WEBRTC_CERT_EMAIL não foi configurado!"
    errors=$((errors + 1))
  fi

  if [ "$EVOLUTION_API_KEY" = "sua-chave-api" ]; then
    warn "EVOLUTION_API_KEY não foi configurada!"
    errors=$((errors + 1))
  fi

  if [ $errors -gt 0 ]; then
    err "Corrija as configurações no topo do script antes de continuar. ($errors erro(s))"
  fi
}

validate_config

# ---- MOSTRAR STATUS ----
echo ""
echo "=================================================="
echo -e "${CYAN}  CENTRAL DE COMUNICAÇÃO - Instalador VPS${NC}"
echo "=================================================="
echo -e "  Domínio: ${GREEN}${DOMAIN}${NC}"
if [ -f "$STATE_FILE" ]; then
  COMPLETED=$(wc -l < "$STATE_FILE")
  info "Retomando instalação... ${COMPLETED} etapa(s) já concluída(s)"
  while IFS= read -r step; do
    echo -e "    ${GREEN}✓${NC} $step"
  done < "$STATE_FILE"
  echo ""
else
  info "Iniciando instalação do zero..."
fi
echo "=================================================="
echo ""

# ============================================================
# ETAPA 1: PRÉ-REQUISITOS
# ============================================================
if ! step_done "prerequisitos"; then
  log "Atualizando sistema e instalando pré-requisitos..."
  run apt update
  apt upgrade -y || true
  run apt install -y build-essential git curl wget sudo \
    libncurses5-dev libssl-dev libxml2-dev libsqlite3-dev \
    uuid-dev libjansson-dev libsrtp2-dev \
    libedit-dev pkg-config unixodbc-dev \
    certbot nginx ufw jq openssl
  mark_done "prerequisitos"
fi

# ============================================================
# ETAPA 2: FIREWALL
# ============================================================
if ! step_done "firewall"; then
  log "Configurando firewall..."
  ufw allow 22/tcp       # SSH
  ufw allow 80/tcp       # HTTP
  ufw allow 443/tcp      # HTTPS
  ufw allow 5060/udp     # SIP
  ufw allow 5061/tcp     # SIP TLS
  ufw allow 8089/tcp     # WebSocket (WSS)
  ufw allow 10000:20000/udp  # RTP Media
  ufw allow 8080/tcp     # Evolution API
  ufw --force enable
  mark_done "firewall"
fi

# ============================================================
# ETAPA 3: ASTERISK - DOWNLOAD E COMPILAÇÃO
# ============================================================
if ! step_done "asterisk_compile"; then
  log "Baixando e compilando Asterisk 20..."
  cd /usr/src
  ASTERISK_VER="20-current"

  # Download apenas se não existir
  if [ ! -f "asterisk-${ASTERISK_VER}.tar.gz" ]; then
    run wget -q https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VER}.tar.gz
  fi

  # Extrair apenas se o diretório não existir
  ASTERISK_DIR=$(find /usr/src -maxdepth 1 -type d -name "asterisk-20*" | head -1)
  if [ -z "$ASTERISK_DIR" ]; then
    run tar xzf asterisk-${ASTERISK_VER}.tar.gz
    ASTERISK_DIR=$(find /usr/src -maxdepth 1 -type d -name "asterisk-20*" | head -1)
  fi

  if [ -z "$ASTERISK_DIR" ]; then
    err "Não foi possível encontrar o diretório do Asterisk após extração"
  fi

  cd "$ASTERISK_DIR"

  run contrib/scripts/install_prereq install
  contrib/scripts/get_mp3_source.sh || true

  run ./configure --with-pjproject-bundled --with-jansson-bundled
  run make menuselect.makeopts
  menuselect/menuselect \
    --enable res_pjsip \
    --enable res_pjsip_transport_websocket \
    --enable res_http_websocket \
    --enable codec_opus \
    --enable res_srtp \
    menuselect.makeopts

  run make -j$(nproc)
  run make install
  run make samples
  run make config
  ldconfig

  adduser --system --group --no-create-home asterisk 2>/dev/null || true
  chown -R asterisk:asterisk /var/lib/asterisk /var/log/asterisk /var/spool/asterisk /var/run/asterisk /etc/asterisk 2>/dev/null || true
  mark_done "asterisk_compile"
fi

# ============================================================
# ETAPA 4: CONFIGURAÇÃO ASTERISK (PJSIP, Dialplan, AMI, HTTP)
# ============================================================
if ! step_done "asterisk_config"; then
  log "Configurando PJSIP, Dialplan, AMI e HTTP..."

  cat > /etc/asterisk/pjsip.conf << 'PJSIP_EOF'
; ========================================
; PJSIP - Transporte e WebRTC
; ========================================

[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0:5060

[transport-wss]
type=transport
protocol=wss
bind=0.0.0.0:8089

; ---- Template para ramais WebRTC ----
[webrtc-template](!)
type=endpoint
transport=transport-wss
context=internal
disallow=all
allow=opus
allow=ulaw
dtls_auto_generate_cert=yes
webrtc=yes
media_encryption=dtls
dtls_verify=no
dtls_setup=actpass
ice_support=yes
media_use_received_transport=yes
rtcp_mux=yes

; ---- Ramais de exemplo ----
[1001](webrtc-template)
auth=1001-auth
aors=1001
callerid="Ramal 1001" <1001>

[1001-auth]
type=auth
auth_type=userpass
username=1001
password=ramal1001senha

[1001-aor]
type=aor
max_contacts=5
remove_existing=yes

[1002](webrtc-template)
auth=1002-auth
aors=1002
callerid="Ramal 1002" <1002>

[1002-auth]
type=auth
auth_type=userpass
username=1002
password=ramal1002senha

[1002-aor]
type=aor
max_contacts=5
remove_existing=yes

[1003](webrtc-template)
auth=1003-auth
aors=1003
callerid="Ramal 1003" <1003>

[1003-auth]
type=auth
auth_type=userpass
username=1003
password=ramal1003senha

[1003-aor]
type=aor
max_contacts=5
remove_existing=yes
PJSIP_EOF

  cat > /etc/asterisk/extensions.conf << 'DIALPLAN_EOF'
[general]
static=yes
writeprotect=no

[internal]
; Chamadas entre ramais (1000-1099)
exten => _10XX,1,NoOp(Chamada interna para ${EXTEN})
 same => n,Dial(PJSIP/${EXTEN},30,tTr)
 same => n,VoiceMail(${EXTEN}@default,u)
 same => n,Hangup()

; URA Principal
exten => 9000,1,Answer()
 same => n,Wait(1)
 same => n,Background(custom/saudacao)
 same => n(menu),Background(custom/menu-principal)
 same => n,WaitExten(5)
 same => n,Goto(menu)

exten => 1,1,NoOp(Vendas)
 same => n,Queue(vendas,tT)
 same => n,Hangup()

exten => 2,1,NoOp(Suporte)
 same => n,Queue(suporte,tT)
 same => n,Hangup()

exten => 3,1,NoOp(Financeiro)
 same => n,Dial(PJSIP/1003,30,tT)
 same => n,Hangup()

exten => 0,1,NoOp(Atendente)
 same => n,Dial(PJSIP/1001,30,tT)
 same => n,Hangup()

; Chamadas externas (ajuste o trunk)
[from-external]
exten => _.,1,NoOp(Chamada externa de ${CALLERID(num)})
 same => n,Goto(internal,9000,1)
DIALPLAN_EOF

  cat > /etc/asterisk/manager.conf << AMI_EOF
[general]
enabled = yes
port = 5038
bindaddr = 127.0.0.1

[${ASTERISK_AMI_USER}]
secret = ${ASTERISK_AMI_PASS}
deny = 0.0.0.0/0.0.0.0
permit = 127.0.0.1/255.255.255.0
read = all
write = all
writetimeout = 5000
AMI_EOF

  # HTTP/WebSocket - usa certs SSL se existirem, senão desabilita TLS
  if [ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
    cat > /etc/asterisk/http.conf << HTTP_EOF
[general]
enabled=yes
bindaddr=0.0.0.0
bindport=8088
tlsenable=yes
tlsbindaddr=0.0.0.0:8089
tlscertfile=/etc/letsencrypt/live/${DOMAIN}/fullchain.pem
tlsprivatekey=/etc/letsencrypt/live/${DOMAIN}/privkey.pem
HTTP_EOF
  else
    cat > /etc/asterisk/http.conf << 'HTTP_EOF'
[general]
enabled=yes
bindaddr=0.0.0.0
bindport=8088
tlsenable=no
HTTP_EOF
    warn "SSL ainda não disponível - HTTP do Asterisk sem TLS (será reconfigurado após SSL)"
  fi

  mark_done "asterisk_config"
fi

# ============================================================
# ETAPA 5: CERTIFICADO SSL
# ============================================================
if ! step_done "ssl"; then
  log "Gerando certificado SSL..."
  # Parar qualquer serviço na porta 80
  systemctl stop nginx 2>/dev/null || true
  fuser -k 80/tcp 2>/dev/null || true
  sleep 2

  if certbot certonly --standalone -d "${DOMAIN}" --email "${WEBRTC_CERT_EMAIL}" --agree-tos --non-interactive; then
    mark_done "ssl"

    # Reconfigurar Asterisk HTTP com TLS agora que temos o cert
    cat > /etc/asterisk/http.conf << HTTP_EOF
[general]
enabled=yes
bindaddr=0.0.0.0
bindport=8088
tlsenable=yes
tlsbindaddr=0.0.0.0:8089
tlscertfile=/etc/letsencrypt/live/${DOMAIN}/fullchain.pem
tlsprivatekey=/etc/letsencrypt/live/${DOMAIN}/privkey.pem
HTTP_EOF
    log "Asterisk HTTP reconfigurado com TLS"
  else
    warn "SSL falhou - verifique se o domínio ${DOMAIN} aponta para este servidor"
    warn "Tente manualmente: certbot certonly --standalone -d ${DOMAIN}"
    warn "Depois re-execute este script para continuar"
    exit 1
  fi
fi

# ============================================================
# ETAPA 6: NGINX
# ============================================================
if ! step_done "nginx"; then
  log "Configurando Nginx..."

  # Verificar se os certs existem antes de configurar HTTPS
  if [ ! -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
    err "Certificado SSL não encontrado. Execute a etapa SSL primeiro."
  fi

  cat > /etc/nginx/sites-available/central << NGINX_EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # WebSocket Asterisk
    location /ws {
        proxy_pass https://127.0.0.1:8089/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_read_timeout 86400;
    }

    # Evolution API
    location /evolution/ {
        proxy_pass http://127.0.0.1:8080/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Painel Web (React SPA)
    location / {
        root /var/www/central-painel;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }
}
NGINX_EOF

  ln -sf /etc/nginx/sites-available/central /etc/nginx/sites-enabled/
  rm -f /etc/nginx/sites-enabled/default

  if nginx -t; then
    run systemctl restart nginx
    mark_done "nginx"
  else
    err "Configuração do Nginx inválida. Verifique /etc/nginx/sites-available/central"
  fi
fi

# ============================================================
# ETAPA 7: POSTGRESQL
# ============================================================
if ! step_done "postgresql"; then
  log "Instalando PostgreSQL..."
  run apt install -y postgresql postgresql-contrib
  run systemctl enable postgresql
  run systemctl start postgresql

  # Aguardar PostgreSQL ficar pronto
  for i in $(seq 1 10); do
    if sudo -u postgres psql -c "SELECT 1" &>/dev/null; then
      break
    fi
    info "Aguardando PostgreSQL iniciar... ($i/10)"
    sleep 2
  done

  log "Configurando banco de dados para Evolution API..."
  sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${POSTGRES_USER}'" | grep -q 1 || \
    run sudo -u postgres psql -c "CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASS}';"
  sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB}'" | grep -q 1 || \
    run sudo -u postgres psql -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};" || true

  POSTGRES_URI="postgresql://${POSTGRES_USER}:${POSTGRES_PASS}@localhost:5432/${POSTGRES_DB}"
  save_var "POSTGRES_URI" "${POSTGRES_URI}"

  # Testar conexão
  if PGPASSWORD="${POSTGRES_PASS}" psql -h localhost -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SELECT 1" &>/dev/null; then
    log "Conexão com PostgreSQL verificada com sucesso"
  else
    warn "Não foi possível verificar a conexão - verifique pg_hba.conf para autenticação md5/scram"
    # Configurar pg_hba para aceitar conexões locais com senha
    PG_HBA=$(sudo -u postgres psql -tc "SHOW hba_file" | tr -d ' ')
    if [ -n "$PG_HBA" ]; then
      # Adicionar regra antes da primeira regra local se não existir
      if ! grep -q "${POSTGRES_USER}" "$PG_HBA"; then
        sed -i "/^# IPv4 local/a host    ${POSTGRES_DB}    ${POSTGRES_USER}    127.0.0.1/32    md5" "$PG_HBA"
        systemctl reload postgresql
        info "pg_hba.conf atualizado para aceitar conexões do usuário ${POSTGRES_USER}"
      fi
    fi
  fi

  mark_done "postgresql"
fi

# Garantir que POSTGRES_URI está disponível
load_vars
if [ -z "$POSTGRES_URI" ]; then
  POSTGRES_URI="postgresql://${POSTGRES_USER}:${POSTGRES_PASS}@localhost:5432/${POSTGRES_DB}"
fi

# ============================================================
# ETAPA 8: NODE.JS
# ============================================================
if ! step_done "nodejs"; then
  log "Instalando Node.js 20..."
  # Verificar se já está instalado
  if command -v node &>/dev/null && node -v | grep -q "v20"; then
    log "Node.js 20 já instalado: $(node -v)"
  else
    run curl -fsSL https://deb.nodesource.com/setup_20.x -o /tmp/nodesource_setup.sh
    run bash /tmp/nodesource_setup.sh
    run apt install -y nodejs
    rm -f /tmp/nodesource_setup.sh
  fi
  log "Node.js: $(node -v) | npm: $(npm -v)"
  mark_done "nodejs"
fi

# ============================================================
# ETAPA 9: EVOLUTION API
# ============================================================
if ! step_done "evolution_api"; then
  log "Instalando Evolution API..."
  cd /opt

  if [ ! -d "evolution-api" ]; then
    run git clone https://github.com/EvolutionAPI/evolution-api.git
  fi
  cd evolution-api

  # Criar .env com variáveis seguras (sem caracteres problemáticos)
  cat > .env << EVOL_EOF
SERVER_URL=https://${DOMAIN}/evolution
AUTHENTICATION_API_KEY=${EVOLUTION_API_KEY}
DATABASE_PROVIDER=postgresql
DATABASE_CONNECTION_URI=${POSTGRES_URI}
DATABASE_SAVE_DATA_INSTANCE=true
DATABASE_SAVE_DATA_NEW_MESSAGE=true
DATABASE_SAVE_MESSAGE_UPDATE=true
DATABASE_SAVE_DATA_CONTACTS=true
DATABASE_SAVE_DATA_CHATS=true
LOG_LEVEL=ERROR,WARN
DEL_INSTANCE=false
EVOL_EOF

  run npm install

  if ! npx prisma generate; then
    err "Prisma generate falhou. Verifique se o schema Prisma está correto."
  fi

  if ! npx prisma db push; then
    warn "Prisma db push falhou - o banco pode não estar acessível"
    warn "Verifique: PGPASSWORD='${POSTGRES_PASS}' psql -h localhost -U ${POSTGRES_USER} -d ${POSTGRES_DB}"
    exit 1
  fi

  if ! npm run build; then
    err "Build da Evolution API falhou. Verifique os erros acima."
  fi

  # Verificar se o build gerou os arquivos
  if [ ! -f "dist/src/main.js" ]; then
    err "Build concluído mas dist/src/main.js não foi gerado"
  fi

  cat > /etc/systemd/system/evolution-api.service << 'SVC_EOF'
[Unit]
Description=Evolution API
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/evolution-api
ExecStart=/usr/bin/node dist/src/main.js
Restart=on-failure
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
SVC_EOF

  mark_done "evolution_api"
fi

# ============================================================
# ETAPA 10: BUILD DO PAINEL WEB
# ============================================================
if ! step_done "painel_web"; then
  log "Fazendo build do painel web..."
  cd /opt

  # Validar URL do repositório
  if [ -d "central-painel" ]; then
    cd central-painel
    git pull || warn "git pull falhou - usando versão atual"
  else
    if [ -z "$GIT_REPO" ]; then
      err "GIT_REPO não configurado! Edite a variável GIT_REPO no topo do script com a URL do seu repositório."
    fi

    # Construir URL com token para repos privados (evita prompt de senha)
    CLONE_URL="$GIT_REPO"
    if [ -n "$GIT_TOKEN" ]; then
      # Transforma https://github.com/user/repo.git → https://TOKEN@github.com/user/repo.git
      CLONE_URL=$(echo "$GIT_REPO" | sed "s|https://|https://${GIT_TOKEN}@|")
      info "Usando token de acesso para clonar repositório privado"
    fi

    run git clone "$CLONE_URL" central-painel
    cd central-painel
  fi

  run npm install
  run npm run build

  # Verificar se o build gerou arquivos
  if [ ! -d "dist" ] || [ -z "$(ls -A dist 2>/dev/null)" ]; then
    err "Build do painel falhou - diretório dist vazio ou inexistente"
  fi

  mkdir -p /var/www/central-painel
  cp -r dist/* /var/www/central-painel/
  chown -R www-data:www-data /var/www/central-painel
  mark_done "painel_web"
fi

# ============================================================
# ETAPA 11: INICIAR SERVIÇOS
# ============================================================
if ! step_done "servicos"; then
  log "Iniciando serviços..."
  systemctl daemon-reload

  systemctl enable asterisk
  systemctl start asterisk || warn "Asterisk não iniciou - verifique: journalctl -u asterisk"

  systemctl enable evolution-api
  systemctl start evolution-api || warn "Evolution API não iniciou - verifique: journalctl -u evolution-api"

  systemctl enable nginx
  systemctl restart nginx || warn "Nginx não reiniciou - verifique: nginx -t"

  # Verificar se todos os serviços estão rodando
  ALL_OK=true
  for svc in asterisk evolution-api nginx postgresql; do
    if ! systemctl is-active --quiet "$svc"; then
      warn "Serviço $svc não está ativo!"
      ALL_OK=false
    fi
  done

  if [ "$ALL_OK" = true ]; then
    mark_done "servicos"
  else
    warn "Alguns serviços não iniciaram. Verifique os logs e re-execute o script."
    exit 1
  fi
fi

# ---- RESUMO ----
echo ""
echo "=================================================="
echo -e "${GREEN}  INSTALAÇÃO CONCLUÍDA COM SUCESSO!${NC}"
echo "=================================================="
echo ""
echo "  Asterisk WebRTC:"
echo "    WSS: wss://${DOMAIN}/ws"
echo "    Ramais: 1001, 1002, 1003"
echo "    AMI: localhost:5038 (user: ${ASTERISK_AMI_USER})"
echo ""
echo "  PostgreSQL:"
echo "    Banco: ${POSTGRES_DB}"
echo "    Usuário: ${POSTGRES_USER}"
echo "    Senha: ${POSTGRES_PASS}"
echo "    URI: ${POSTGRES_URI}"
echo ""
echo "  Evolution API (WhatsApp):"
echo "    URL: https://${DOMAIN}/evolution"
echo "    API Key: ${EVOLUTION_API_KEY}"
echo ""
echo "  Painel Web: https://${DOMAIN}/"
echo ""
echo "  COMANDOS ÚTEIS:"
echo "    Status:  sudo ./install.sh --status"
echo "    Resetar: sudo ./install.sh --reset"
echo "    Logs Asterisk:  journalctl -u asterisk -f"
echo "    Logs Evolution: journalctl -u evolution-api -f"
echo "    Logs Nginx:     tail -f /var/log/nginx/error.log"
echo ""
echo "  PRÓXIMOS PASSOS:"
echo "    1. Conecte o WhatsApp:"
echo "       curl -X POST https://${DOMAIN}/evolution/instance/create \\"
echo "         -H 'apikey: ${EVOLUTION_API_KEY}' \\"
echo "         -H 'Content-Type: application/json' \\"
echo "         -d '{\"instanceName\": \"central\", \"integration\": \"WHATSAPP-BAILEYS\"}'"
echo ""
echo "    2. Para atualizar o painel:"
echo "       cd /opt/central-painel && git pull && npm run build && cp -r dist/* /var/www/central-painel/"
echo ""
echo "=================================================="
