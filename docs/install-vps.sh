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

# ---- ARQUIVO DE ESTADO (checkpoint) ----
STATE_FILE="/opt/.central-install-state"
VARS_FILE="/opt/.central-install-vars"

# Cores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

# Reset se solicitado
if [ "$1" = "--reset" ]; then
  rm -f "$STATE_FILE" "$VARS_FILE"
  log "Estado resetado. Execute novamente sem --reset."
  exit 0
fi

# Status dos serviços
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

# Funções de checkpoint
step_done() {
  grep -qxF "$1" "$STATE_FILE" 2>/dev/null
}

mark_done() {
  echo "$1" >> "$STATE_FILE"
  log "Etapa '$1' concluída ✓"
}

# Salvar/carregar variáveis persistentes (ex: senha gerada)
save_var() {
  # Remove entrada antiga se existir
  sed -i "/^$1=/d" "$VARS_FILE" 2>/dev/null || true
  echo "$1=$2" >> "$VARS_FILE"
}

load_vars() {
  if [ -f "$VARS_FILE" ]; then
    source "$VARS_FILE"
  fi
}

# Carregar variáveis de execuções anteriores
load_vars

# Gerar senha do PostgreSQL apenas na primeira execução
if [ -z "$POSTGRES_PASS" ]; then
  POSTGRES_PASS="EvoPass$(openssl rand -hex 8)"
  save_var "POSTGRES_PASS" "$POSTGRES_PASS"
fi

# Mostrar status
echo ""
echo "=================================================="
echo -e "${CYAN}  CENTRAL DE COMUNICAÇÃO - Instalador VPS${NC}"
echo "=================================================="
if [ -f "$STATE_FILE" ]; then
  COMPLETED=$(wc -l < "$STATE_FILE")
  info "Retomando instalação... ${COMPLETED} etapa(s) já concluída(s)"
  info "Etapas concluídas:"
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
  apt update && apt upgrade -y
  apt install -y build-essential git curl wget sudo \
    libncurses5-dev libssl-dev libxml2-dev libsqlite3-dev \
    uuid-dev libjansson-dev libsrtp2-dev \
    libedit-dev pkg-config unixodbc-dev \
    certbot nginx ufw jq
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
  if [ ! -f "asterisk-${ASTERISK_VER}.tar.gz" ]; then
    wget -q https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VER}.tar.gz
  fi
  tar xzf asterisk-${ASTERISK_VER}.tar.gz
  cd asterisk-20*/

  contrib/scripts/install_prereq install
  contrib/scripts/get_mp3_source.sh

  ./configure --with-pjproject-bundled --with-jansson-bundled
  make menuselect.makeopts
  menuselect/menuselect \
    --enable res_pjsip \
    --enable res_pjsip_transport_websocket \
    --enable res_http_websocket \
    --enable codec_opus \
    --enable res_srtp \
    menuselect.makeopts

  make -j$(nproc)
  make install
  make samples
  make config
  ldconfig

  adduser --system --group --no-create-home asterisk 2>/dev/null || true
  chown -R asterisk:asterisk /var/lib/asterisk /var/log/asterisk /var/spool/asterisk /var/run/asterisk /etc/asterisk
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

  cat > /etc/asterisk/http.conf << 'HTTP_EOF'
[general]
enabled=yes
bindaddr=0.0.0.0
bindport=8088
tlsenable=yes
tlsbindaddr=0.0.0.0:8089
tlscertfile=/etc/letsencrypt/live/DOMAIN/fullchain.pem
tlsprivatekey=/etc/letsencrypt/live/DOMAIN/privkey.pem
HTTP_EOF

  sed -i "s|DOMAIN|${DOMAIN}|g" /etc/asterisk/http.conf
  mark_done "asterisk_config"
fi

# ============================================================
# ETAPA 5: CERTIFICADO SSL
# ============================================================
if ! step_done "ssl"; then
  log "Gerando certificado SSL..."
  systemctl stop nginx 2>/dev/null || true
  if certbot certonly --standalone -d ${DOMAIN} --email ${WEBRTC_CERT_EMAIL} --agree-tos --non-interactive; then
    mark_done "ssl"
  else
    warn "SSL falhou - você pode tentar novamente re-executando o script"
    warn "Ou configure manualmente: certbot certonly --standalone -d ${DOMAIN}"
  fi
  systemctl start nginx 2>/dev/null || true
fi

# ============================================================
# ETAPA 6: NGINX
# ============================================================
if ! step_done "nginx"; then
  log "Configurando Nginx..."

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
  
  if step_done "ssl"; then
    nginx -t && systemctl restart nginx
  else
    warn "Nginx configurado mas SSL pendente - será ativado quando o SSL for concluído"
  fi
  mark_done "nginx"
fi

# ============================================================
# ETAPA 7: POSTGRESQL
# ============================================================
if ! step_done "postgresql"; then
  log "Instalando PostgreSQL..."
  apt install -y postgresql postgresql-contrib
  systemctl enable postgresql
  systemctl start postgresql

  log "Configurando banco de dados para Evolution API..."
  sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${POSTGRES_USER}'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASS}';"
  sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB}'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};"

  POSTGRES_URI="postgresql://${POSTGRES_USER}:${POSTGRES_PASS}@localhost:5432/${POSTGRES_DB}"
  save_var "POSTGRES_URI" "$POSTGRES_URI"
  mark_done "postgresql"
fi

# Garantir que POSTGRES_URI está disponível
load_vars

# ============================================================
# ETAPA 8: NODE.JS
# ============================================================
if ! step_done "nodejs"; then
  log "Instalando Node.js 20..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt install -y nodejs
  mark_done "nodejs"
fi

# ============================================================
# ETAPA 9: EVOLUTION API
# ============================================================
if ! step_done "evolution_api"; then
  log "Instalando Evolution API..."
  cd /opt
  if [ ! -d "evolution-api" ]; then
    git clone https://github.com/EvolutionAPI/evolution-api.git
  fi
  cd evolution-api

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

  npm install
  npx prisma generate || warn "Prisma generate falhou"
  npx prisma db push || warn "Prisma db push falhou - verifique a conexão com PostgreSQL"
  npm run build || warn "Build da Evolution API falhou"

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
  if [ -d "central-painel" ]; then
    cd central-painel && git pull
  else
    git clone https://github.com/SEU_USUARIO/SEU_REPOSITORIO.git central-painel
    cd central-painel
  fi

  npm install
  npm run build
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
  systemctl start asterisk
  systemctl enable evolution-api
  systemctl start evolution-api
  systemctl enable nginx
  systemctl restart nginx 2>/dev/null || true
  mark_done "servicos"
fi

# ---- RESUMO ----
echo ""
echo "=================================================="
echo -e "${GREEN}  INSTALAÇÃO CONCLUÍDA!${NC}"
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
echo ""
echo "  Evolution API (WhatsApp):"
echo "    URL: https://${DOMAIN}/evolution"
echo "    API Key: ${EVOLUTION_API_KEY}"
echo ""
echo "  Nginx: https://${DOMAIN}"
echo "  Painel Web: https://${DOMAIN}/"
echo ""
echo "  ARQUIVOS DE ESTADO:"
echo "    Checkpoint: ${STATE_FILE}"
echo "    Variáveis: ${VARS_FILE}"
echo "    Para resetar: sudo ./install.sh --reset"
echo ""
echo "  PRÓXIMOS PASSOS:"
echo "    1. Edite DOMAIN e senhas no topo deste script"
echo "    2. Troque a URL do git clone pela do seu repositório GitHub"
echo "       (Conecte o GitHub no Lovable: Settings > GitHub)"
echo "    3. Conecte o WhatsApp: POST ${DOMAIN}/evolution/instance/create"
echo "    4. Para atualizar o painel: cd /opt/central-painel && git pull && npm run build && cp -r dist/* /var/www/central-painel/"
echo ""
echo "=================================================="
