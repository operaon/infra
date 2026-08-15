#!/usr/bin/env bash
# Renova certificados Let's Encrypt e recarrega o Nginx.
# Pode ser executado via cron no host duas vezes por dia.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="${COMPOSE_FILE:-$REPO_ROOT/docker/docker-compose.yml}"
ENV_FILE="${ENV_FILE:-$REPO_ROOT/docker/.env}"
LOG_PREFIX="[renew-certs] $(date '+%Y-%m-%d %H:%M:%S')"

[ -f "$ENV_FILE" ] || {
    echo "$LOG_PREFIX — ERRO: arquivo de ambiente não encontrado: $ENV_FILE" >&2
    exit 1
}

if ! docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" --profile certbot run --rm --entrypoint certbot certbot \
    renew \
    --webroot \
    --webroot-path=/var/www/certbot \
    --non-interactive \
    --quiet; then
    echo "$LOG_PREFIX — ERRO: certbot renew falhou." >&2
    exit 1
fi

echo "$LOG_PREFIX — Renovação verificada. Recarregando nginx..."
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" exec -T nginx nginx -s reload
echo "$LOG_PREFIX — Nginx recarregado com sucesso."
