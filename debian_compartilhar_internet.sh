#!/bin/bash

################################################################################
# Script Name:  debian_update.sh
# Description:  Faz a atualizacao do Debian e limpeza dos pacotes baixados
#               ou desnecessário para o sistema.
# Author: Suzano Bitencourt
# Date: 20/11/2024
# Version: 1.0
# License: GPL-3.0
# Usage: 
#   ./debian_update.sh
#
# Requirements:
#   - O script deve ser executado com privilégios de superusuário (root).
#   - O apt é um sistema de gerenciamento de pacotes de programas padrão para 
#       sistemas operacionais baseados em Debian e Ubuntu. 
#
# Features:
#   0. Verifica se o script está sendo executado como root
#   1. Verifica se existe conexao com a internet
#   2. Atualiza o repositorio
#   3. Repara pacotes quebrados
#   4. Atualiza o sistema
#   5. Remove pacotes baixados pelo APT
#   6. Remove pacotes que não tiveram seu download concluído
#   7. Remove dependências que não são mais necessárias pelo sistema
#   8. Reinicia o sistema
#
# Example:
#   sudo ./debian_update.sh
#
# Notes:
#   - Nenhuma observacao ou erro relatado no funcionamento do script.
#
################################################################################

# Função para compartilhar a conexão de internet
compartilhar_conexao() {
    # Defina o nome da interface Wi-Fi e da interface Ethernet
    # Comando para exibir nome da interface Wi-fi e interface Ethernet
    # ip link show
    WIFI_INTERFACE="wlp2s0"  # Substitua pelo nome da sua interface Wi-Fi
    ETH_INTERFACE="enp3s0"  # Substitua pelo nome da sua interface Ethernet

    # Habilitar o compartilhamento de internet
    sudo iptables -t nat -A POSTROUTING -o $WIFI_INTERFACE -j MASQUERADE
    sudo iptables -A FORWARD -i $ETH_INTERFACE -o $WIFI_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A FORWARD -i $ETH_INTERFACE -o $WIFI_INTERFACE -j ACCEPT

    # Configurar o IP estático para a interface Ethernet
    sudo ip addr add 192.168.123.100/24 dev $ETH_INTERFACE
    sudo ip link set $ETH_INTERFACE up

    # Habilitar o forwarding de pacotes
    echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null

    echo "Conexão compartilhada com sucesso!"
}

# Função para restaurar a configuração da placa de rede
restaurar_configuracao() {
    # Defina o nome da interface Ethernet
    ETH_INTERFACE="enp3s0"  # Substitua pelo nome da sua interface Ethernet

    # Remover as regras do iptables
    sudo iptables -t nat -D POSTROUTING -o $WIFI_INTERFACE -j MASQUERADE
    sudo iptables -D FORWARD -i $ETH_INTERFACE -o $WIFI_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -D FORWARD -i $ETH_INTERFACE -o $WIFI_INTERFACE -j ACCEPT

    # Restaurar o IP da interface Ethernet
    sudo ip addr flush dev $ETH_INTERFACE
    sudo ip link set $ETH_INTERFACE down

    # Desabilitar o forwarding de pacotes
    echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null

    echo "Configuração da placa de rede restaurada ao estado padrão."
}

# Menu de opções
echo "Escolha uma opção:"
echo "1 - Compartilhar conexão"
echo "2 - Restaurar configuração"
read -p "Opção: " opcao

case $opcao in
    1)
        compartilhar_conexao
        ;;
    2)
        restaurar_configuracao
        ;;
    *)
        echo "Opção inválida!"
        ;;
esac