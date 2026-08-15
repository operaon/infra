#!/usr/bin/env bash
# Emite o certificado Let's Encrypt inicial para o stack Operaon.
# A configuração é lida de docker/.env; nenhum domínio fica hardcoded aqui.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="${COMPOSE_FILE:-$REPO_ROOT/docker/docker-compose.yml}"
ENV_FILE="${ENV_FILE:-$REPO_ROOT/docker/.env}"

[ -f "$ENV_FILE" ] || {
    echo "ERRO: arquivo de ambiente não encontrado: $ENV_FILE" >&2
    echo "Copie docker/.env.example para docker/.env e preencha os valores de runtime." >&2
    exit 1
}

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

DOMAINS="${DOMAINS:-}"
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-}"
DOMAIN="${DOMAIN:-$(printf '%s' "$DOMAINS" | cut -d',' -f1 | tr -d '[:space:]')}"
CERT_NAME="${CERT_NAME:-$DOMAIN}"

[ -n "$DOMAINS" ] || { echo "ERRO: DOMAINS deve ser definido em $ENV_FILE" >&2; exit 1; }
[ -n "$LETSENCRYPT_EMAIL" ] || { echo "ERRO: LETSENCRYPT_EMAIL deve ser definido em $ENV_FILE" >&2; exit 1; }
[ -n "$CERT_NAME" ] || { echo "ERRO: CERT_NAME deve ser definido ou derivável de DOMAINS" >&2; exit 1; }

DOMAIN_ARGS=()
OLD_IFS="$IFS"
IFS=','
for domain in $DOMAINS; do
    domain="$(printf '%s' "$domain" | tr -d '[:space:]')"
    [ -n "$domain" ] || continue
    DOMAIN_ARGS+=( -d "$domain" )
done
IFS="$OLD_IFS"
[ "${#DOMAIN_ARGS[@]}" -gt 0 ] || { echo "ERRO: DOMAINS não contém domínios válidos" >&2; exit 1; }

echo "=== [init-certs] Verificando se o nginx está rodando..."
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps nginx | grep -q "running" || {
    echo "ERRO: o container nginx não está rodando. Suba-o antes:" >&2
    echo "  docker compose --env-file $ENV_FILE -f $COMPOSE_FILE up -d nginx" >&2
    exit 1
}

echo "=== [init-certs] Emitindo certificado $CERT_NAME para: $DOMAINS"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" --profile certbot run --rm certbot \
    certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --non-interactive \
        --agree-tos \
        --email "$LETSENCRYPT_EMAIL" \
        --cert-name "$CERT_NAME" \
        "${DOMAIN_ARGS[@]}"

echo
echo "=== [init-certs] Certificado emitido com sucesso."
echo "O certificado está em /etc/letsencrypt/live/$CERT_NAME/ dentro do volume Docker certbot_certs."
echo
echo "Recrie o nginx para que o entrypoint detecte o certificado:"
echo "  docker compose --env-file $ENV_FILE -f $COMPOSE_FILE up -d --force-recreate nginx"
echo
echo "Para renovação automática no host, agende:"
echo "  $REPO_ROOT/scripts/renew-certs.sh"
