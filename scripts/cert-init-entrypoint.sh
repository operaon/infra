#!/bin/sh
# scripts/cert-init-entrypoint.sh
#
# Provisionamento automático de certificado SSL, rodado como um
# "init container" (serviço cert-init no docker-compose.yml) ANTES do
# nginx subir. Não requer nenhuma etapa manual — acontece sozinho a
# cada "docker compose up".
#
# Lógica:
#   1. Já existe certificado válido (não expira nos próximos 30 dias)?
#      → não faz nada, sai imediatamente.
#   2. Tenta emitir um certificado real via Let's Encrypt (modo
#      standalone: o próprio certbot ocupa a porta 80 temporariamente,
#      já que o nginx ainda não subiu neste ponto — sem dependência de
#      webroot/nginx rodando). Só funciona se o DNS dos domínios
#      apontar publicamente para esta máquina (ambiente de produção).
#   3. Se falhar (esperado em ambiente local, sem DNS público) → gera
#      automaticamente um certificado autoassinado com SAN (Subject
#      Alternative Name) correto para todos os domínios do projeto,
#      para que HTTPS local funcione sem intervenção manual.
#
# O nginx (nginx/docker-entrypoint.d/10-enable-ssl.sh) detecta
# sozinho, no seu próprio boot, se há certificado em
# /etc/letsencrypt/live/velyonrobotics.com/ e liga o HTTPS — o mesmo
# caminho serve tanto para certificado real quanto autoassinado.
set -e

CERT_DIR="/etc/letsencrypt/live/velyonrobotics.com"
EMAIL="${LETSENCRYPT_EMAIL:-admin@velyonrobotics.com}"
DOMAINS="${DOMAINS:-velyonrobotics.com,www.velyonrobotics.com,fisioterapeuta.velyonrobotics.com,api.velyonrobotics.com}"

# ---- 1. Certificado existente ainda válido? ----
if [ -f "$CERT_DIR/fullchain.pem" ] && openssl x509 -checkend 2592000 -noout -in "$CERT_DIR/fullchain.pem" >/dev/null 2>&1; then
    echo "[cert-init] Certificado existente ainda válido por mais de 30 dias. Nada a fazer."
    exit 0
fi

if [ -f "$CERT_DIR/fullchain.pem" ]; then
    echo "[cert-init] Certificado existente expira em breve — tentando renovar."
fi

# ---- 2. Monta a lista de flags -d para o certbot ----
DOMAIN_ARGS=""
OLD_IFS="$IFS"
IFS=","
for d in $DOMAINS; do
    DOMAIN_ARGS="$DOMAIN_ARGS -d $d"
done
IFS="$OLD_IFS"

# ---- 3. Tenta Let's Encrypt (modo standalone, porta 80 livre pois o nginx ainda não subiu) ----
echo "[cert-init] Tentando emitir certificado via Let's Encrypt (standalone)..."
if certbot certonly \
    --standalone \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    --cert-name velyonrobotics.com \
    $DOMAIN_ARGS \
    2>&1; then
    echo "[cert-init] Certificado Let's Encrypt emitido/renovado com sucesso."
    exit 0
fi

# ---- 4. Fallback automático: certificado autoassinado com SAN correto ----
echo "[cert-init] Let's Encrypt indisponível (normal em ambiente local, sem DNS público)."
echo "[cert-init] Gerando certificado autoassinado de fallback com SAN para: $DOMAINS"

mkdir -p "$CERT_DIR"

SAN=""
OLD_IFS="$IFS"
IFS=","
first=1
for d in $DOMAINS; do
    if [ "$first" = "1" ]; then
        SAN="DNS:$d"
        first=0
    else
        SAN="$SAN,DNS:$d"
    fi
done
IFS="$OLD_IFS"

openssl req -x509 -nodes -newkey rsa:2048 -days 825 \
    -keyout "$CERT_DIR/privkey.pem" \
    -out "$CERT_DIR/fullchain.pem" \
    -subj "/C=BR/ST=PB/L=JoaoPessoa/O=Velyon/CN=velyonrobotics.com" \
    -addext "subjectAltName=$SAN"

echo "[cert-init] Certificado autoassinado gerado com sucesso."
echo "[cert-init] O navegador vai exibir aviso de 'conexão não é privada' até você"
echo "[cert-init] aceitar o certificado (ou instalar sua CA local, ex: mkcert -install)."
exit 0
