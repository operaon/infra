#!/bin/sh
# scripts/cert-init-entrypoint.sh
#
# Provisionamento automático de certificado SSL.
# Lógica atualizada para maior resiliência:
#   1. Verifica se já existe cert válido.
#   2. Tenta Let's Encrypt Standalone (ideal para boot inicial).
#   3. Se falhar (ex: porta 80 ocupada), tenta Let's Encrypt Webroot.
#   4. Fallback final: Certificado Autoassinado.

set -e

CERT_DIR="/etc/letsencrypt/live/velyonrobotics.com"
EMAIL="${LETSENCRYPT_EMAIL:-admin@velyonrobotics.com}"
DOMAINS="${DOMAINS:-velyonrobotics.com,www.velyonrobotics.com,fisioterapeuta.velyonrobotics.com,api.velyonrobotics.com}"
WEBROOT_PATH="/var/www/certbot"

# ---- 1. Certificado existente ainda válido? ----
if [ -f "$CERT_DIR/fullchain.pem" ] && openssl x509 -checkend 2592000 -noout -in "$CERT_DIR/fullchain.pem" >/dev/null 2>&1; then
    echo "[cert-init] Certificado existente ainda válido por mais de 30 dias. Nada a fazer."
    exit 0
fi

# ---- 2. Monta a lista de flags -d ----
DOMAIN_ARGS=""
OLD_IFS="$IFS"
IFS=","
for d in $DOMAINS; do
    DOMAIN_ARGS="$DOMAIN_ARGS -d $d"
done
IFS="$OLD_IFS"

# ---- 3. Tenta Standalone (Porta 80 livre) ----
echo "[cert-init] Tentando Let's Encrypt (Standalone)..."
if certbot certonly --standalone --non-interactive --agree-tos --email "$EMAIL" --cert-name velyonrobotics.com $DOMAIN_ARGS; then
    echo "[cert-init] Sucesso via Standalone."
    exit 0
fi

# ---- 4. Tenta Webroot (Se o Nginx já estiver rodando ou mapeado) ----
echo "[cert-init] Standalone falhou. Tentando Let's Encrypt (Webroot)..."
mkdir -p "$WEBROOT_PATH"
if certbot certonly --webroot --webroot-path="$WEBROOT_PATH" --non-interactive --agree-tos --email "$EMAIL" --cert-name velyonrobotics.com $DOMAIN_ARGS; then
    echo "[cert-init] Sucesso via Webroot."
    exit 0
fi

# ---- 5. Fallback: Autoassinado ----
echo "[cert-init] Let's Encrypt falhou em ambos os modos. Gerando autoassinado de fallback..."
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

echo "[cert-init] Certificado autoassinado gerado."
exit 0
