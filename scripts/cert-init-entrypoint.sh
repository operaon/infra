#!/bin/sh
# Provisionamento de certificados TLS para o proxy Operaon.
# A lista de domínios e o nome do certificado vêm exclusivamente do ambiente.
set -eu

DOMAINS="${DOMAINS:-}"
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-}"
[ -n "$DOMAINS" ] || { echo "[cert-init] DOMAINS é obrigatório." >&2; exit 1; }
[ -n "$LETSENCRYPT_EMAIL" ] || { echo "[cert-init] LETSENCRYPT_EMAIL é obrigatório." >&2; exit 1; }

DOMAIN="${DOMAIN:-$(printf '%s' "$DOMAINS" | cut -d',' -f1 | tr -d '[:space:]')}"
CERT_NAME="${CERT_NAME:-$DOMAIN}"
CERT_DIR="/etc/letsencrypt/live/$CERT_NAME"
DHPARAM_FILE="${DHPARAM_FILE:-/etc/letsencrypt/dhparam.pem}"
WEBROOT_PATH="${WEBROOT_PATH:-/var/www/certbot}"

[ -n "$DOMAIN" ] || { echo "[cert-init] DOMAINS não contém um domínio válido." >&2; exit 1; }

# ---- 1. Geração de DHParam (segurança adicional) ----
if [ ! -f "$DHPARAM_FILE" ]; then
    echo "[cert-init] Gerando dhparam.pem; isso pode demorar alguns minutos..."
    openssl dhparam -out "$DHPARAM_FILE" 2048
    echo "[cert-init] dhparam.pem gerado com sucesso."
fi

# ---- 2. Certificado existente ainda válido? ----
if [ -f "$CERT_DIR/fullchain.pem" ] && openssl x509 -checkend 2592000 -noout -in "$CERT_DIR/fullchain.pem" >/dev/null 2>&1; then
    echo "[cert-init] Certificado existente ainda válido em $CERT_DIR. Nada a fazer."
    exit 0
fi

# ---- 3. Constrói argumentos -d sem avaliação de shell ----
set --
OLD_IFS="$IFS"
IFS=','
for domain in $DOMAINS; do
    domain="$(printf '%s' "$domain" | tr -d '[:space:]')"
    [ -n "$domain" ] || continue
    set -- "$@" -d "$domain"
done
IFS="$OLD_IFS"
[ "$#" -gt 0 ] || { echo "[cert-init] DOMAINS não contém entradas válidas." >&2; exit 1; }

# ---- 4. Tenta Let's Encrypt (Standalone -> Webroot) ----
echo "[cert-init] Solicitando certificado $CERT_NAME para: $DOMAINS"
if certbot certonly --standalone --non-interactive --agree-tos --email "$LETSENCRYPT_EMAIL" --cert-name "$CERT_NAME" "$@"; then
    echo "[cert-init] Sucesso via Standalone."
    exit 0
fi

echo "[cert-init] Standalone falhou. Tentando via Webroot..."
mkdir -p "$WEBROOT_PATH"
if certbot certonly --webroot --webroot-path="$WEBROOT_PATH" --non-interactive --agree-tos --email "$LETSENCRYPT_EMAIL" --cert-name "$CERT_NAME" "$@"; then
    echo "[cert-init] Sucesso via Webroot."
    exit 0
fi

# ---- 5. Fallback autoassinado para permitir o boot local ----
if [ -f "$CERT_DIR/fullchain.pem" ]; then
    echo "[cert-init] AVISO: Let's Encrypt falhou, mas existe um certificado em $CERT_DIR. Mantendo-o para evitar downtime."
    exit 0
fi

echo "[cert-init] Let's Encrypt falhou. Gerando certificado autoassinado de fallback..."
mkdir -p "$CERT_DIR"
SAN=""
OLD_IFS="$IFS"
IFS=','
first=1
for domain in $DOMAINS; do
    domain="$(printf '%s' "$domain" | tr -d '[:space:]')"
    [ -n "$domain" ] || continue
    if [ "$first" = "1" ]; then SAN="DNS:$domain"; first=0; else SAN="$SAN,DNS:$domain"; fi
done
IFS="$OLD_IFS"

openssl req -x509 -nodes -newkey rsa:2048 -days 825 \
    -keyout "$CERT_DIR/privkey.pem" \
    -out "$CERT_DIR/fullchain.pem" \
    -subj "/C=BR/ST=PB/L=JoaoPessoa/O=Operaon/CN=$DOMAIN" \
    -addext "subjectAltName=$SAN"

chmod 600 "$CERT_DIR/privkey.pem"
echo "[cert-init] Certificado autoassinado de fallback gerado em $CERT_DIR."
exit 0
