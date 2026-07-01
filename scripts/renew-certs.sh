#!/bin/bash
# =============================================================
# scripts/renew-certs.sh
#
# Renova os certificados Let's Encrypt e recarrega o nginx.
# Deve ser executado via cron no host duas vezes por dia.
# =============================================================

set -euo pipefail

COMPOSE_FILE="/opt/velyon/velyon_infra/docker/docker-compose.yml"
LOG_PREFIX="[renew-certs] $(date '+%Y-%m-%d %H:%M:%S')"

echo "$LOG_PREFIX — Iniciando verificação de renovação..."

# Tenta renovar usando o método webroot validado.
# O certbot só renova se o cert vencer em menos de 30 dias.
docker compose -f "$COMPOSE_FILE" --profile certbot run --rm --entrypoint "certbot" certbot \
    renew \
    --webroot \
    --webroot-path=/var/www/certbot \
    --non-interactive \
    --quiet

EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo "$LOG_PREFIX — ERRO: certbot renew falhou com código $EXIT_CODE."
    exit $EXIT_CODE
fi

echo "$LOG_PREFIX — Renovação verificada. Recarregando nginx..."

# Recarrega o nginx para aplicar os certificados renovados
docker compose -f "$COMPOSE_FILE" exec -T nginx nginx -s reload

echo "$LOG_PREFIX — Nginx recarregado com sucesso."
