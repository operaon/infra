#!/bin/sh
# nginx/docker-entrypoint.d/20-auto-reload.sh
#
# Monitora o arquivo de certificado e recarrega o Nginx se ele mudar.
# Isso permite que o container cert-renew atualize o SSL sem downtime.

(
while true; do
    # Dorme por 24 horas antes de verificar
    sleep 24h
    
    # Se o certificado existir, dá um reload suave no Nginx
    if [ -f "/etc/letsencrypt/live/velyonrobotics.com/fullchain.pem" ]; then
        echo "[auto-reload] Recarregando Nginx para garantir uso dos certificados mais recentes..."
        nginx -s reload
    fi
done
) &
