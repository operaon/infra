#!/bin/bash
# =============================================================
# scripts/init-certs.sh
#
# Emite os certificados Let's Encrypt pela primeira vez.
#
# PRÉ-REQUISITOS antes de rodar:
#   1. DNS dos 5 domínios apontando para o IP do servidor
#   2. Stack rodando com nginx em modo HTTP (sem HTTPS ainda)
#      → suba só o nginx primeiro: docker compose up -d nginx
#   3. Porta 80 acessível publicamente
#
# Uso:
#   chmod +x scripts/init-certs.sh
#   ./scripts/init-certs.sh
# =============================================================

set -euo pipefail

COMPOSE_FILE="/opt/velyon/velyon_infra/docker/docker-compose.yml"
EMAIL="admin@velyonrobotics.com"

echo "=== [init-certs] Verificando se o nginx está rodando..."
docker compose -f "$COMPOSE_FILE" ps nginx | grep -q "running" || {
    echo "ERRO: o container nginx não está rodando. Suba-o antes:"
    echo "  docker compose -f $COMPOSE_FILE up -d nginx"
    exit 1
}

echo "=== [init-certs] Emitindo certificado via Let's Encrypt (webroot)..."

docker compose -f "$COMPOSE_FILE" --profile certbot run --rm certbot \
    certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --non-interactive \
        --agree-tos \
        --email "$EMAIL" \
        -d velyonrobotics.com \
        -d www.velyonrobotics.com \
        -d fisioterapeuta.velyonrobotics.com \
        -d paciente.velyonrobotics.com \
        -d api.velyonrobotics.com

echo ""
echo "=== [init-certs] Certificado emitido com sucesso!"
echo ""
echo "Próximos passos:"
echo "  1. O cert está em: /etc/letsencrypt/live/velyonrobotics.com/"
echo "     (dentro do volume Docker 'certbot_certs')"
echo ""
echo "  2. Recrie o container do nginx para ele detectar o certificado"
echo "     e habilitar HTTPS automaticamente (um simples 'reload' NÃO"
echo "     basta, pois a detecção roda no boot do container):"
echo "     docker compose -f $COMPOSE_FILE up -d --force-recreate nginx"
echo ""
echo "  3. Instale o cron de renovação automática no host:"
echo "     crontab -e"
echo "     Adicione a linha:"
echo "     0 3,15 * * * /opt/velyon/velyon_infra/scripts/renew-certs.sh >> /var/log/velyon-renew.log 2>&1"
