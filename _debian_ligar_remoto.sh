#!/bin/bash

################################################################################
# Script Name: ligar_pc_remoto.sh
# Description: Liga um computador remotamente usando Wake-on-LAN.
#              1. Solicita informações como MAC Address e IP.
#              2. Verifica se o computador já está ligado.
#              3. Envia um "pacote mágico" para ligar o computador.
#              4. Verifica novamente se o computador está online.
#              5. Informa ao usuário se a operação teve sucesso.
# Author: Suzano [Seu Nome Completo]
# Date: 21/11/2024
# Version: 1.0
# License: GPL-3.0
#
# Requirements:
#   - Ferramenta 'wakeonlan' instalada.
#   - Ferramenta 'ping' para verificar status.
#
# Usage:
#   ./ligar_pc_remoto.sh
################################################################################

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    echo "Erro: Este script deve ser executado como root."
    exit 1
fi

# Verificar se a ferramenta wakeonlan está instalada
if ! command -v wakeonlan &> /dev/null; then
    echo "A ferramenta 'wakeonlan' não está instalada. Instalando agora..."
    sudo apt update && sudo apt install wakeonlan -y
fi

# Solicitar informações do usuário
echo "Informe as informações necessárias para ligar o computador remotamente."
read -p "Digite o MAC Address do computador (ex.: AA:BB:CC:DD:EE:FF): " MAC_ADDRESS
read -p "Digite o IP do computador (ex.: 192.168.1.100): " IP_ADDRESS
read -p "Digite o nome da interface de rede (ex.: eth0 ou wlan0): " INTERFACE

# Verificar se o computador já está ligado
echo "Verificando se o computador já está online..."
if ping -c 2 "$IP_ADDRESS" &> /dev/null; then
    echo "O computador com IP $IP_ADDRESS já está ligado."
    exit 0
fi

# Enviar o pacote mágico para ligar o computador
echo "Enviando pacote mágico para $MAC_ADDRESS..."
wakeonlan -i "$IP_ADDRESS" "$MAC_ADDRESS"

# Aguardar um tempo para o computador iniciar
echo "Aguardando 30 segundos para o computador iniciar..."
sleep 30

# Verificar novamente se o computador está ligado
echo "Verificando novamente o status do computador..."
if ping -c 2 "$IP_ADDRESS" &> /dev/null; then
    echo "Sucesso! O computador com IP $IP_ADDRESS foi ligado."
else
    echo "Falha: O computador não respondeu. Verifique se o Wake-on-LAN está configurado corretamente."
fi