#!/bin/sh
# scripts/cert-renew-loop.sh
#
# Loop infinito para renovação automática de certificados dentro do Docker.
# Verifica a cada 12 horas.

echo "[cert-renew] Iniciando serviço de renovação automática..."

while true; do
    echo "[cert-renew] $(date): Verificando necessidade de renovação..."
    
    # Tenta renovar
    certbot renew \
        --webroot \
        --webroot-path=/var/www/certbot \
        --non-interactive \
        --quiet
    
    # Nota: O recarregamento do Nginx deve ser feito via sinal ou 
    # compartilhando o socket do docker, mas a forma mais limpa aqui 
    # é o Nginx também ter um script que recarrega periodicamente ou 
    # usar um sinal HUP se os containers compartilharem o PID namespace.
    # Para manter simples e robusto, o Nginx no seu projeto já pode ser 
    # configurado para recarregar ou apenas deixamos o cert renovado 
    # e o próximo restart do stack aplica.
    
    echo "[cert-renew] Verificação concluída. Próxima verificação em 12 horas."
    sleep 12h
done
