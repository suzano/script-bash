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

# Definição de códigos de cores ANSI
VERMELHO='\033[0;31m'
VERDE='\033[0;32m'
AMARELO='\033[0;33m'
AZUL='\033[0;34m'
MAGENTA='\033[0;35m'
CIANO='\033[0;36m'
BRANCO='\033[0;37m'
NEGRITO='\033[1m'
NORMAL='\033[0m' # Reset para a cor padrão

# 0. Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    echo -e "${VERMELHO}Erro: Este script deve ser executado como root.${NORMAL}"
    exit 1
fi

# 1. Verifica se existe conexao com a internet
clear
echo -e "${AMARELO}${NEGRITO}1. Verificando conexão com a Internet...${NORMAL}"
ping -c 2 google.com &> /dev/null #¹
if [ $? -eq 0 ]; then #²
    echo -e "${VERDE}Conexão com a Internet estável.${NORMAL}"
else
    echo -e "${VERMELHO}Sem conexão com a Internet. Verifique a rede e tente novamente.${NORMAL}"
    exit 1
fi
echo ""

# 2. Atualiza o repositorio
echo -e "${AMARELO}${NEGRITO}2. Atualizando repositórios...${NORMAL}"
sudo apt update -y
if [ $? -ne 0 ]; then
    echo -e "${VERMELHO}Erro ao atualizar repositórios. Verifique a configuração do apt.${NORMAL}"
    exit 1
else
    echo -e "${VERDE}Repositórios atualizados com sucesso.${NORMAL}"
fi
echo ""

# 3. Repara pacotes quebrados
echo -e "${AMARELO}${NEGRITO}3. Reparando pacotes quebrados...${NORMAL}"
sudo dpkg --configure -a
sudo apt --fix-broken install
if [ $? -ne 0 ]; then
    echo -e "${VERMELHO}Erro ao reparar pacotes quebrados. Tente usar o comando: sudo dpkg --force-remove-reinstreq --remove <pacote>.${NORMAL}"
    exit 1
else
    echo -e "${VERDE}Pacotes quebrados reparados com sucesso.${NORMAL}"
fi
echo ""

# 4. Atualiza o sistema
echo -e "${AMARELO}${NEGRITO}4. Atualizando o sistema...${NORMAL}"
sudo apt upgrade -y
# sudo apt dist-upgrade -y
if [ $? -ne 0 ]; then
    echo -e "${VERMELHO}Erro ao atualizar o sistema. Verifique a configuração ou os pacotes instalados.${NORMAL}"
    exit 1
else
    echo -e "${VERDE}Sistema atualizado com sucesso.${NORMAL}"
fi
echo ""

# 5. Remove pacotes baixados pelo APT
echo -e "${AMARELO}${NEGRITO}5. Removendos todos os pacotes baixados pelo APT...${NORMAL}"
sudo apt clean -y
if [ $? -ne 0 ]; then
    echo -e "${VERMELHO}Erro ao remover pacotes baixados pelo APT.${NORMAL}"
    exit 1
else
    echo -e "${VERDE}Pacotes baixados removidos com sucesso.${NORMAL}"
fi
echo ""

# 6. Remove pacotes que não tiveram seu download concluído
echo -e "${AMARELO}${NEGRITO}6. Removendo pacotes incompletos...${NORMAL}"
sudo apt autoclean -y
if [ $? -ne 0 ]; then
    echo -e "${VERMELHO}Erro ao remover pacotes incompletos.${NORMAL}"
    exit 1
else
    echo -e "${VERDE}Pacotes incompletos removidos com sucesso.${NORMAL}"
fi
echo ""

# 7. Remove dependências que não são mais necessárias pelo sistema
echo -e "${AMARELO}${NEGRITO}7. Removendo dependências que não são mais necessárias pelo sistema...${NORMAL}"
sudo apt autoremove -y
if [ $? -ne 0 ]; then
    echo -e "${VERMELHO}Erro ao remover dependências que não são mais necessárias pelo sistema.${NORMAL}"
    exit 1
else
    echo -e "${VERDE}Dependências desnecessárias removidas com sucesso.${NORMAL}"
fi
echo ""

# 8 - Instala e atualiza programas específicos
programas=("htop" "neofetch" "cmatrix")

echo -e "${AMARELO}${NEGRITO}8. Verificando e instalando/atualizando programas...${NORMAL}"
for programa in "${programas[@]}"; do
  echo -e "${AMARELO}${NEGRITO}Verificando o programa: $programa${NORMAL}"
  if dpkg -s "$programa" > /dev/null 2>&1; then
    echo "$programa está instalado."
    # Tenta reinstalar para garantir a versão mais recente
    echo -e "${VERDE}Reinstalando $programa para garantir a versão mais recente...${NORMAL}"
    sudo apt install --reinstall -y "$programa"
  else
    echo -e "${VERMELHO}$programa não está instalado. Instalando...${NORMAL}"
    sudo apt install -y "$programa"
  fi
done
echo ""

# 9. Reinicia o sistema
echo -e "${AMARELO}${NEGRITO}9. Reiniciando o sistema em 10 segundos. Pressione Ctrl+C para cancelar.${NORMAL}"
sleep 10
sudo reboot

#¹ O comando "&>/dev/null" redireciona a saída e os erros de um programa para o arquivo especial "/dev/null", que descarta intencionalmente qualquer dado enviado para ele.
#² A variável "$?" armazena o status de saída do último comando executado.