#!/bin/bash

# Configurações do e-mail
EMAIL_DESTINO="seuemail@exemplo.com"
ASSUNTO="Relatório de Portas Abertas e Serviços - $(hostname) - $(date)"

# Verifica portas abertas e os serviços usando o comando netstat ou ss
echo "Coletando informações das portas abertas e serviços..."
PORTAS_SERVICOS=$(ss -tuln | awk 'NR>1 {print $1, $4, $5}')

# Cria o corpo do e-mail
CORPO_EMAIL="
Relatório de Portas Abertas e Serviços - $(hostname)

Data/Hora: $(date)

Portas e Serviços:
$PORTAS_SERVICOS
"

# Exibe as informações no terminal (opcional)
echo "$CORPO_EMAIL"

# Envia o e-mail usando o comando mail
echo "$CORPO_EMAIL" | mail -s "$ASSUNTO" "$EMAIL_DESTINO"

if [ $? -eq 0 ]; then
    echo "E-mail enviado com sucesso para $EMAIL_DESTINO."
else
    echo "Falha ao enviar o e-mail. Verifique as configurações."
    exit 1
fi