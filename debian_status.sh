#!/bin/bash

################################################################################
# Script Name:  debian_status.sh
# Description:  Faz a atualizacao do Debian e limpeza dos pacotes baixados
#               ou desnecessário para o sistema.
#
# Author: Suzano Bitencourt
# Date: 20/11/2024
# Version: 1.0
# License: GPL-3.0
# Usage: 
#   ./debian_status.sh
#
# Requirements:
#   - O script deve ser executado com privilégios de superusuário (root).
#   - O apt é um sistema de gerenciamento de pacotes de programas padrão para 
#       sistemas operacionais baseados em Debian e Ubuntu. 
#
# Features:
#   1. Verifica se existe conexao com a internet
#   2. Verifica se os programa para o funcionamento do script estao 
#      instalados no sistema
#   3. Repara pacotes quebrados
#   4. Atualiza o sistema
#   5. Remove pacotes baixados pelo APT
#   6. Remove pacotes que não tiveram seu download concluído
#   7. Remove dependências que não são mais necessárias pelo sistema
#   8. Reinicia o sistema
#
# Example:
#   ./debian_status.sh
#
# Notes:
#   - Nenhuma observacao ou erro relatado no funcionamento do script.
#
################################################################################

# Programas dos quais o script depende para funcionar.
PROGRAMAS_OBRIGATORIOS=("mailutils" "lm-sensors" "cmatrix" "neofetch")

# 1. Verifica se existe conexao com a internet
clear
echo "1. Verificando conexão com a Internet..."
ping -c 2 google.com &> /dev/null 
if [ $? -eq 0 ]; then
    echo "Conexão com a Internet estável."
else
    echo "Sem conexão com a Internet. Verifique a rede e tente novamente."
    exit 1
fi
echo ""

# 2. Verifica se as dependencias do script estao instalados no sistema
echo "2. Verificando programas obrigatórios no sistema..."
# 2.1 Função que verifica se um programa esta instalado
verifica_programa() {
    local programa=$1
    dpkg -l | grep -qw "$programa" &>/dev/null
    return $?
}
# 2.2 Verifica cada programa da lista
PROGRAMAS_AUSENTES=()
for programa in "${PROGRAMAS_OBRIGATORIOS[@]}"; do
    verifica_programa "$programa"
    if [ $? -ne 0 ]; then
        echo "Programa não encontrado: $programa"
        PROGRAMAS_AUSENTES+=("$programa")
    else
        echo "Programa encontrado: $programa"
    fi
done
# 2.3. Instala os programas obrigatorios
if [ ${#PROGRAMAS_AUSENTES[@]} -eq 0 ]; then
    echo "Todos os programas obrigatórios estão instalados!"
else
    echo "Instalando os programas obrigatorio..."
    sudo apt update
    for programa in "${PROGRAMAS_AUSENTES[@]}"; do
        #echo "  - $programa"
        sudo apt install -y $programa
    done
fi
echo ""

# 3. Informacoes do sistema
echo "3. Coletando informacoes do sistema..."





# 4. Informacoes de email
# 4.1 Informacoes da conta
# Conta de E-mail: syslog.reports@gmail.com
# Senha: PCSXXX#XXXXX
# 4.2 Instalacao e configuracao
# sudo apt install postfix
# Escolha a opcao: Site de Internet
# smtp.gmail.com

# sudo nano /etc/postfix/main.cf (Altere linhas e adicione caso não exista)
# relayhost = [smtp.gmail.com]:587
# smtp_sasl_auth_enable = yes
# smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
# mtp_sasl_security_options = noanonymous
# smtp_tls_CAfile = /etc/postfix/cacert.pem
# smtp_use_tls = yes
# inet_interfaces = loopback-only
# sudo nano /etc/postfix/sasl_passwd (Crie o arquivo e escreva a linha abaixo)
# [smtp.gmail.com]:587 syslog.reports@gmail.com:PCSXXX#XXXXX
# sudo chmod 400 /etc/postfix/sasl_passwd
# sudo postmap /etc/postfix/sasl_passwd
# Valide o certificado digital
# cat /etc/ssl/certs/Thawte_Premium_Server_CA.pem | sudo tee -a /etc/postfix/cacert.pem
# Reinicie o servico:
# sudo /etc/init.d/postfix reload
# Teste o servico:
# echo "Mensagem" | mail -s "Assunto" suzanobitencourt@gmail.com



# Configuracoes do e-mail
EMAIL_DESTINO="suzanobitencourt@gmail.com"
ASSUNTO="Status do Computador $(hostname) - $(date)"

# Informacoes do computador
HOSTNAME=$(hostname)
DISTRO=$(echo "Distro")
IP=$(echo "IP")
VELOCIDADE_DOWNLOAD=$(echo "Velocidade de Download")
VELOCIDADE_UPLOAD=$(echo "Velocidade de Upload")
CPU_USO=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | xargs printf "%.2f%%")
MEMORIA_USO=$(free -m | awk '/Mem:/ { printf "%.2f%%", $3/$2 * 100.0 }')
DISCO_USO=$(df -h / | awk '/\// {print $5}')
TEMPERATURA=$(sensors | grep -Po 'Tdie:\s+\+\K[0-9.]+')

# Cria o corpo do e-mail
CORPO_EMAIL="
Status do Computador - $(hostname)

Data/Hora: $(date)

Hostname: ${HOSTNAME}
Sistema Operacional: ${DISTRO}
IP: ${IP}
Velocidade de Download: ${VELOCIDADE_DOWNLOAD}
Velocidade de Upload: ${VELOCIDADE_UPLOAD}
Uso do Processador: ${CPU_USO}
Temperatura da CPU: ${TEMPERATURA}°C
Uso da Memória RAM: ${MEMORIA_USO}
Uso do Disco (root): ${DISCO_USO}
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

# Pacotes Necessários: Ins
#sudo apt update
#sudo apt install -y mailutils lm-sensors

# Configuração de Sensores:
#sudo sensors-detect

# Configuração de E-mail
# echo "Teste de envio" | mail -s "Teste" seuemail@exemplo.com

# 3. 
