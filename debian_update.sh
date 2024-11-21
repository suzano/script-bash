#!/bin/bash

################################################################################
# Script Name:  debian_update.sh
# Description:  Faz a atualizacao do Debian e limpeza dos pacotes baixados
#               ou desnecessário para o sistema.
#
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

# 1. Verifica se existe conexao com a internet
clear
echo "1. Verificando conexão com a Internet..."
ping -c 2 google.com &> /dev/null #¹
if [ $? -eq 0 ]; then #²
    echo "Conexão com a Internet estável."
else
    echo "Sem conexão com a Internet. Verifique a rede e tente novamente."
    exit 1
fi
echo ""

# 2. Atualiza o repositorio
echo "2. Atualizando repositórios..."
sudo apt update -y
if [ $? -ne 0 ]; then
    echo "Erro ao atualizar repositórios. Verifique a configuração do apt."
    exit 1
fi
echo ""

# 3. Repara pacotes quebrados
echo "3. Reparando pacotes quebrados..."
sudo dpkg --configure -a
if [ $? -ne 0 ]; then
    echo "Erro ao reparar pacotes quebrados. Tente usar o comando: sudo dpkg --force-remove-reinstreq --remove <pacote>."
    exit 1
fi
echo ""

# 4. Atualiza o sistema
echo "4. Atualizando o sistema..."
sudo apt upgrade -y
if [ $? -ne 0 ]; then
    echo "Erro ao atualizar o sistema. Verifique a configuração ou os pacotes instalados."
    exit 1
fi
echo ""

# 5. Remove pacotes baixados pelo APT
echo "5. Removendos todos os pacotes baixados pelo APT..."
sudo apt clean -y
if [ $? -ne 0 ]; then
    echo "Erro ao remover pacotes baixados pelo APT."
    exit 1
fi
echo ""

# 6. Remove pacotes que não tiveram seu download concluído
echo "6. Removendo pacotes incompletos..."
sudo apt autoclean -y
if [ $? -ne 0 ]; then
    echo "Erro ao remover pacotes incompletos."
    exit 1
fi
echo ""

# 7. Remove dependências que não são mais necessárias pelo sistema
echo "7. Removendo dependências que não são mais necessárias pelo sistema..."
sudo apt autoremove -y
if [ $? -ne 0 ]; then
    echo "Erro ao remover dependências que não são mais necessárias pelo sistema."
    exit 1
fi
echo ""

# 8. Reinicia o sistema
echo "8. Reiniciando o sistema em 10 segundos. Pressione Ctrl+C para cancelar."
sleep 10
sudo reboot

#¹ O comando "&>/dev/null" redireciona a saída e os erros de um programa para o arquivo especial "/dev/null", que descarta intencionalmente qualquer dado enviado para ele.
#² A variável "$?" armazena o status de saída do último comando executado.