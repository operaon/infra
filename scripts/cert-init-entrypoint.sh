#!/bin/sh
# scripts/cert-init-entrypoint.sh
#
# Provisionamento automático de SSL com padrões de segurança Enterprise.
set -e

CERT_DIR="/etc/letsencrypt/live/velyonrobotics.com"
DHPARAM_FILE="/etc/letsencrypt/dhparam.pem"
EMAIL="${LETSENCRYPT_EMAIL:-admin@velyonrobotics.com}"
DOMAINS="${DOMAINS:-velyonrobotics.com,www.velyonrobotics.com,fisioterapeuta.velyonrobotics.com,api.velyonrobotics.com}"
WEBROOT_PATH="/var/www/certbot"

# ---- 1. Geração de DHParam (Segurança Adicional) ----
if [ ! -f "$DHPARAM_FILE" ]; then
    echo "[cert-init] Gerando dhparam.pem (isso pode demorar alguns minutos, mas acontece apenas uma vez)..."
    openssl dhparam -out "$DHPARAM_FILE" 2048
    echo "[cert-init] dhparam.pem gerado com sucesso."
fi

# ---- 2. Certificado existente ainda válido? ----
if [ -f "$CERT_DIR/fullchain.pem" ] && openssl x509 -checkend 2592000 -noout -in "$CERT_DIR/fullchain.pem" >/dev/null 2>&1; then
    echo "[cert-init] Certificado existente ainda válido. Nada a fazer."
    exit 0
fi

# ---- 3. Monta a lista de flags -d ----
DOMAIN_ARGS=""
OLD_IFS="$IFS"
IFS=","
for d in $DOMAINS; do
    DOMAIN_ARGS="$DOMAIN_ARGS -d $d"
done
IFS="$OLD_IFS"

# ---- 4. Tenta Let's Encrypt (Híbrido: Standalone -> Webroot) ----
echo "[cert-init] Iniciando processo de obtenção de certificado real..."

# Tentativa Standalone
if certbot certonly --standalone --non-interactive --agree-tos --email "$EMAIL" --cert-name velyonrobotics.com $DOMAIN_ARGS; then
    echo "[cert-init] Sucesso via Standalone."
    exit 0
fi

# Tentativa Webroot
echo "[cert-init] Standalone falhou. Tentando via Webroot..."
mkdir -p "$WEBROOT_PATH"
if certbot certonly --webroot --webroot-path="$WEBROOT_PATH" --non-interactive --agree-tos --email "$EMAIL" --cert-name velyonrobotics.com $DOMAIN_ARGS; then
    echo "[cert-init] Sucesso via Webroot."
    exit 0
fi

# ---- 5. Fallback Final: Autoassinado (com proteção para não apagar certs reais se existirem) ----
if [ -f "$CERT_DIR/fullchain.pem" ]; then
    echo "[cert-init] AVISO: Let's Encrypt falhou, mas já existe um certificado (mesmo que expirado). Mantendo o atual para evitar downtime total."
    exit 0
fi

echo "[cert-init] Let's Encrypt falhou. Gerando autoassinado para permitir o boot do Nginx..."
mkdir -p "$CERT_DIR"
SAN=""
OLD_IFS="$IFS"
IFS=","
first=1
for d in $DOMAINS; do
    if [ "$first" = "1" ]; then SAN="DNS:$d"; first=0; else SAN="$SAN,DNS:$d"; fi
done
IFS="$OLD_IFS"

openssl req -x509 -nodes -newkey rsa:2048 -days 825 \
    -keyout "$CERT_DIR/privkey.pem" \
    -out "$CERT_DIR/fullchain.pem" \
    -subj "/C=BR/ST=PB/L=JoaoPessoa/O=Velyon/CN=velyonrobotics.com" \
    -addext "subjectAltName=$SAN"

echo "[cert-init] Certificado autoassinado de fallback gerado."
exit 0
