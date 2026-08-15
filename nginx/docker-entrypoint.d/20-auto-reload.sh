#!/bin/sh
# Script auxiliar opcional para recarga periódica do Nginx após renovação TLS.
# Não é copiado pela imagem por padrão; a renovação oficial usa scripts/renew-certs.sh.
set -eu

DOMAIN="${DOMAIN:-$(printf '%s' "${DOMAINS:-operaon.local}" | cut -d',' -f1)}"
CERT_NAME="${CERT_NAME:-$DOMAIN}"
CERT_FILE="/etc/letsencrypt/live/$CERT_NAME/fullchain.pem"

(
    while true; do
        sleep 24h
        if [ -f "$CERT_FILE" ]; then
            echo "[auto-reload] Recarregando Nginx para aplicar o certificado mais recente..."
            nginx -s reload
        fi
    done
) &
