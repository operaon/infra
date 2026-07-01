# scripts/init-local-certs.ps1
#
# Gera um certificado HTTPS LOCALMENTE CONFIÁVEL (via mkcert) para os
# domínios do projeto e o injeta no volume Docker `certbot_certs`, no
# mesmo caminho que o nginx já procura em produção
# (/etc/letsencrypt/live/velyonrobotics.com/). Como o entrypoint do
# nginx (nginx/docker-entrypoint.d/10-enable-ssl.sh) detecta esse
# caminho automaticamente, HTTPS liga sozinho — sem editar configs.
#
# Por que isso é necessário: APIs do navegador como geolocalização
# (navigator.geolocation), câmera/microfone, clipboard, etc. só
# funcionam em "contexto seguro" (HTTPS ou localhost). Acessando por
# domínio customizado em HTTP puro, o navegador bloqueia essas APIs
# sem nem exibir o prompt de permissão.
#
# Uso: rodar da raiz do velyon_infra (ex: G:\novo\velyon_infra):
#   powershell -ExecutionPolicy Bypass -File scripts\init-local-certs.ps1

$ErrorActionPreference = "Stop"

$domains = @(
    "velyonrobotics.com",
    "www.velyonrobotics.com",
    "fisioterapeuta.velyonrobotics.com",
    "api.velyonrobotics.com"
)

# ---- 1. Verifica se o mkcert está instalado ----
if (-not (Get-Command mkcert -ErrorAction SilentlyContinue)) {
    Write-Host "mkcert não encontrado. Instale com uma das opções abaixo e rode este script de novo:" -ForegroundColor Yellow
    Write-Host "  choco install mkcert"
    Write-Host "  scoop install mkcert"
    Write-Host "  (ou baixe o .exe em https://github.com/FiloSottile/mkcert/releases)"
    exit 1
}

# ---- 2. Registra a CA local do mkcert como confiável no Windows/navegadores ----
Write-Host "Registrando autoridade certificadora local (mkcert -install)..." -ForegroundColor Cyan
mkcert -install

# ---- 3. Gera o certificado para os domínios do projeto ----
$certDir = Join-Path $PSScriptRoot "..\.local-certs"
New-Item -ItemType Directory -Force -Path $certDir | Out-Null

Write-Host "Gerando certificado para: $($domains -join ', ')" -ForegroundColor Cyan
Push-Location $certDir
mkcert -cert-file fullchain.pem -key-file privkey.pem $domains
Pop-Location

# ---- 4. Injeta o certificado no volume Docker certbot_certs ----
# Reaproveita o serviço "certbot" do compose, que já monta esse volume
# (com permissão de escrita) em /etc/letsencrypt — não precisa descobrir
# o nome exato do volume nem criar container avulso.
Write-Host "Copiando certificado para o volume certbot_certs..." -ForegroundColor Cyan
$dockerDir = Join-Path $PSScriptRoot "..\docker"

docker compose -f "$dockerDir\docker-compose.yml" --profile certbot run --rm `
    -v "${certDir}:/tmp/local-certs:ro" `
    --entrypoint sh `
    certbot `
    -c "mkdir -p /etc/letsencrypt/live/velyonrobotics.com && cp /tmp/local-certs/fullchain.pem /tmp/local-certs/privkey.pem /etc/letsencrypt/live/velyonrobotics.com/"

# ---- 5. Recria o nginx para ele detectar o certificado no boot ----
Write-Host "Recriando o nginx para habilitar HTTPS..." -ForegroundColor Cyan
docker compose -f "$dockerDir\docker-compose.yml" up -d --force-recreate nginx

Write-Host ""
Write-Host "Pronto! HTTPS local habilitado com certificado confiável." -ForegroundColor Green
Write-Host "Acesse via https:// (não http://) para que APIs como geolocalização funcionem:"
foreach ($d in $domains) { Write-Host "  https://$d" }
