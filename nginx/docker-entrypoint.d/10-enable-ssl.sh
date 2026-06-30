#!/bin/sh
# Executado automaticamente pela imagem oficial nginx:alpine antes do
# nginx iniciar (qualquer *.sh em /docker-entrypoint.d/ roda nesse hook).
#
# Detecta se há certificados Let's Encrypt válidos montados (volume
# certbot_certs). Se houver (ambiente de produção, após
# scripts/init-certs.sh), habilita os server blocks HTTPS. Se não
# houver (ex.: máquina local, sem domínio público), o Nginx segue
# servindo tudo em HTTP simples (porta 80) — sem erro, sem travar o boot.
set -e

CERT_DIR="/etc/letsencrypt/live/velyonrobotics.com"
TEMPLATE="/etc/nginx/conf.d/20-https.conf.template"
TARGET="/etc/nginx/conf.d/20-https.conf"

if [ -f "$CERT_DIR/fullchain.pem" ] && [ -f "$CERT_DIR/privkey.pem" ]; then
    echo "[10-enable-ssl] Certificado SSL encontrado em $CERT_DIR — habilitando HTTPS (porta 443)."
    cp "$TEMPLATE" "$TARGET"
else
    echo "[10-enable-ssl] Nenhum certificado SSL encontrado — servindo apenas HTTP (porta 80)."
    rm -f "$TARGET"
fi
