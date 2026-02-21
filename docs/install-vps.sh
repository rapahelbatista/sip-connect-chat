#!/bin/bash
# ================================================================
# CENTRAL DE COMUNICAÇÃO - Script de Instalação VPS
# Asterisk 20 (WebRTC) + Evolution API (WhatsApp)
# Compatível com Ubuntu 22.04 / 24.04
# ================================================================
# USO: chmod +x install.sh && sudo ./install.sh
# ================================================================

set -e

# ---- CONFIGURAÇÕES (EDITE ANTES DE EXECUTAR) ----
DOMAIN="seu-dominio.com"           # Domínio do VPS (ou IP público)
ASTERISK_AMI_USER="admin"          # Usuário AMI do Asterisk
ASTERISK_AMI_PASS="SuaSenhaForte123!"  # Senha AMI
WEBRTC_CERT_EMAIL="seu@email.com"  # Email para certificado SSL
EVOLUTION_API_KEY="sua-chave-api"  # Chave da Evolution API
POSTGRES_DB="evolution"            # Nome do banco PostgreSQL
POSTGRES_USER="evolution"          # Usuário PostgreSQL
POSTGRES_PASS="EvoPass$(openssl rand -hex 8)"  # Senha gerada automaticamente

# Cores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# ---- PRÉ-REQUISITOS ----
log "Atualizando sistema..."
apt update && apt upgrade -y
apt install -y build-essential git curl wget sudo \
  libncurses5-dev libssl-dev libxml2-dev libsqlite3-dev \
  uuid-dev libjansson-dev libsrtp2-dev \
  libedit-dev pkg-config unixodbc-dev \
  certbot nginx ufw jq

# ---- FIREWALL ----
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

# ---- ASTERISK 20 ----
log "Baixando Asterisk 20..."
cd /usr/src
ASTERISK_VER="20-current"
wget -q https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VER}.tar.gz
tar xzf asterisk-${ASTERISK_VER}.tar.gz
cd asterisk-20*/

log "Instalando dependências do Asterisk..."
contrib/scripts/install_prereq install
contrib/scripts/get_mp3_source.sh

log "Compilando Asterisk..."
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

# Criar usuário asterisk
adduser --system --group --no-create-home asterisk 2>/dev/null || true
chown -R asterisk:asterisk /var/lib/asterisk /var/log/asterisk /var/spool/asterisk /var/run/asterisk /etc/asterisk

# ---- CONFIGURAÇÃO PJSIP (WebRTC) ----
log "Configurando PJSIP para WebRTC..."

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

# ---- DIALPLAN ----
log "Configurando Dialplan..."

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

# ---- AMI (Asterisk Manager Interface) ----
log "Configurando AMI..."

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

# ---- HTTP para WebSocket ----
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

# ---- CERTIFICADO SSL ----
log "Gerando certificado SSL..."
systemctl stop nginx 2>/dev/null || true
certbot certonly --standalone -d ${DOMAIN} --email ${WEBRTC_CERT_EMAIL} --agree-tos --non-interactive || warn "SSL falhou - configure manualmente"
systemctl start nginx 2>/dev/null || true

# ---- NGINX REVERSE PROXY ----
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
nginx -t && systemctl restart nginx

# ---- POSTGRESQL ----
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
log "PostgreSQL configurado: ${POSTGRES_DB}"

# ---- EVOLUTION API (WhatsApp) ----
log "Instalando Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

log "Instalando Evolution API..."
cd /opt
git clone https://github.com/EvolutionAPI/evolution-api.git
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

# Systemd service para Evolution API
cat > /etc/systemd/system/evolution-api.service << 'SVC_EOF'
[Unit]
Description=Evolution API
After=network.target

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

# ---- BUILD DO PAINEL WEB ----
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

# ---- INICIAR SERVIÇOS ----
log "Iniciando serviços..."
systemctl daemon-reload
systemctl enable asterisk
systemctl start asterisk
systemctl enable evolution-api
systemctl start evolution-api
systemctl enable nginx

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
echo "  Evolution API (WhatsApp):"
echo "    URL: https://${DOMAIN}/evolution"
echo "    API Key: ${EVOLUTION_API_KEY}"
echo ""
echo "  Nginx: https://${DOMAIN}"
echo "  Painel Web: https://${DOMAIN}/"
echo ""
echo "  PRÓXIMOS PASSOS:"
echo "    1. Edite DOMAIN e senhas no topo deste script"
echo "    2. Troque a URL do git clone pela do seu repositório GitHub"
echo "       (Conecte o GitHub no Lovable: Settings > GitHub)"
echo "    3. Conecte o WhatsApp: POST ${DOMAIN}/evolution/instance/create"
echo "    4. Para atualizar o painel: cd /opt/central-painel && git pull && npm run build && cp -r dist/* /var/www/central-painel/"
echo ""
echo "=================================================="
