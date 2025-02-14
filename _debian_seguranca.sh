#!/bin/bash

################################################################################
# Script Name:  debian_update.sh
# Description:  Analisa e arquiva logs antigos do sistema (como /var/log/) e 
#               limpa logs desnecessários para liberar espaço.
#               Auxilia na manutenção de servidores com espaço limitado.
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
#   ./debian_update.sh
#
# Notes:
#   - Nenhuma observacao ou erro relatado no funcionamento do script.
#
################################################################################

# Função para exibir mensagens formatadas
function log() {
    echo -e "\n[+] $1"
}

# Função para verificar se um comando está instalado
function check_command() {
    if ! command -v $1 &> /dev/null; then
        log "Erro: $1 não está instalado. Por favor, instale-o para continuar."
        exit 1
    fi
}

# Verificar dependências
log "Verificando dependências..."
check_command nmap
check_command wireshark
check_command curl

# Passo 1: Identificar dispositivos conectados
log "Identificando dispositivos conectados à rede..."
nmap -sn 192.168.0.1/24 -oN dispositivos_conectados.txt
log "Resultados salvos em dispositivos_conectados.txt."

# Passo 2: Verificar portas abertas no roteador
log "Verificando portas abertas no roteador..."
ROUTER_IP="192.168.0.1"  # Substitua pelo IP do seu roteador, se necessário
nmap -sV $ROUTER_IP -oN portas_abertas.txt
log "Resultados salvos em portas_abertas.txt."

# Passo 3: Analisar tráfego da rede (captura de pacotes)
log "Iniciando captura de pacotes com Wireshark..."
log "A captura será salva em trafego_rede.pcap. Pressione Ctrl+C para parar."
tshark -i wlan0 -w trafego_rede.pcap  # Substitua wlan0 pela interface de rede correta
log "Captura de pacotes concluída. Arquivo salvo em trafego_rede.pcap."

# Passo 4: Verificar vulnerabilidades no roteador
log "Verificando vulnerabilidades no roteador..."
log "Acessando Shodan.io para verificar exposição na internet..."
ROUTER_PUBLIC_IP=$(curl -s ifconfig.me)
log "Seu IP público é: $ROUTER_PUBLIC_IP"
log "Acesse https://www.shodan.io/host/$ROUTER_PUBLIC_IP para verificar vulnerabilidades."

# Passo 5: Verificar segurança da rede Wi-Fi
log "Verificando segurança da rede Wi-Fi..."
log "Recomendação: Use ferramentas como Aircrack-ng ou Kismet para testar a força da senha Wi-Fi."
log "Essa etapa requer ferramentas externas e não pode ser totalmente automatizada."

# Passo 6: Documentar resultados
log "Documentando resultados..."
echo "Relatório de Análise de Segurança da Rede" > relatorio_seguranca.txt
echo "----------------------------------------" >> relatorio_seguranca.txt
echo "Dispositivos Conectados:" >> relatorio_seguranca.txt
cat dispositivos_conectados.txt >> relatorio_seguranca.txt
echo -e "\nPortas Abertas no Roteador:" >> relatorio_seguranca.txt
cat portas_abertas.txt >> relatorio_seguranca.txt
echo -e "\nTráfego de Rede Capturado: trafego_rede.pcap" >> relatorio_seguranca.txt
echo -e "\nVerificação de Vulnerabilidades: https://www.shodan.io/host/$ROUTER_PUBLIC_IP" >> relatorio_seguranca.txt
log "Relatório final salvo em relatorio_seguranca.txt."

# Conclusão
log "Análise de segurança concluída!"
log "Revise os arquivos gerados e tome as ações necessárias para corrigir vulnerabilidades."
