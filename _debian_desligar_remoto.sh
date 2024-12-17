#!/bin/bash

################################################################################
# Script Name: desligar_pc_remoto.sh
# Description: Desliga um computador remotamente usando SSH.
#              1. Solicita informações como IP e usuário SSH.
#              2. Verifica se o computador está ligado.
#              3. Envia o comando para desligar o computador.
#              4. Verifica se o computador foi desligado com sucesso.
# Author: Suzano [Seu Nome Completo]
# Date: 21/11/2024
# Version: 1.0
# License: GPL-3.0
#
# Requirements:
#   - Acesso SSH configurado no computador remoto.
#   - Permissões adequadas para desligar o sistema.
#   - Ferramenta 'ping' para verificar o status.
#
# Usage:
#   ./desligar_pc_remoto.sh
################################################################################

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    echo "Erro: Este script deve ser executado como root."
    exit 1
fi

# Solicitar informações do usuário
echo "Informe as informações necessárias para desligar o computador remotamente."
read -p "Digite o IP do computador (ex.: 192.168.1.100): " IP_ADDRESS
read -p "Digite o usuário SSH (ex.: usuario): " SSH_USER

# Verificar se o computador está ligado
echo "Verificando se o computador com IP $IP_ADDRESS está online..."
if ! ping -c 2 "$IP_ADDRESS" &> /dev/null; then
    echo "O computador não está respondendo. Ele pode já estar desligado."
    exit 0
fi

# Enviar o comando de desligamento via SSH
echo "Enviando comando de desligamento para o computador $IP_ADDRESS..."
ssh -o ConnectTimeout=10 "$SSH_USER@$IP_ADDRESS" 'sudo shutdown -h now' &> /dev/null

# Aguardar alguns segundos para o desligamento
echo "Aguardando 30 segundos para o computador desligar..."
sleep 30

# Verificar novamente se o computador está desligado
echo "Verificando novamente o status do computador..."
if ! ping -c 2 "$IP_ADDRESS" &> /dev/null; then
    echo "Sucesso! O computador com IP $IP_ADDRESS foi desligado."
else
    echo "Falha: O computador ainda está respondendo. Verifique as configurações de SSH e permissões."
fi