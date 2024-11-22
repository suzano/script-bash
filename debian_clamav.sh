#!/bin/bash

################################################################################
# Script Name: debian_clamav.sh
# Description: Este script verifica se o ClamAV está instalado, instala-o se
#              necessário, atualiza a base de dados de vírus, realiza uma
#              verificação completa do sistema em busca de vírus e move 
#              qualquer ameaça encontrada para a quarentena.
# Author: Suzano Bitencourt
# Date: 20/11/2024
# Version: 1.0
# License: GPL-3.0
# Usage: 
#   ./debian_clamav.sh
#
# Requirements:
#   - O script deve ser executado com privilégios de superusuário (root).
#   - O ClamAV deve estar configurado corretamente no sistema.
#
# Features:
#   - Verifica se o ClamAV está instalado.
#   - Instala o ClamAV caso não esteja presente.
#   - Atualiza a base de dados de vírus.
#   - Realiza uma verificação completa no sistema.
#   - Coloca em quarentena os arquivos encontrados com vírus ou outras ameaças.
#
# Example:
#   ./debian_clamav.sh
#
# Notes:
#   - As ameaças detectadas serão movidas para o diretório /tmp/quarentena.
#   - O script é compatível com sistemas baseados em Debian (Ubuntu, etc).
#
################################################################################

# 1. Verifica se o clamav está instalado
clear
echo "1. Verificando se o ClamAV esta instalado..."
dpkg -l | grep -i clamav &>/dev/null #¹

if [ $? -eq 0 ]; then #²
    echo "O ClamAV já está instalado."
else
    echo "O ClamAV não está instalado. Instalando..."
    sudo apt update
    sudo apt install -y clamav clamav-daemon

    if [ $? -eq 0 ]; then #²
        echo "ClamAV instalado com sucesso."
    else
        echo "Erro ao instalar o ClamAV."
        exit 1
    fi
fi
echo ""

# 2. Verifica e atualiza a base de dados de vírus
echo "2. Verificando e atualizando a base de dados do ClamAV..."
sudo service clamav-freshclam stop
sudo rm -f /usr/local/etc/freshclam.conf
sudo ln -s /etc/clamav/freshclam.conf /usr/local/etc/freshclam.conf
sudo rm /var/log/clamav/freshclam.log
sudo freshclam --quiet
sudo service clamav-freshclam start
echo "Atualizada"
echo ""

# 3. Iniciar a verificacao completa do sistema
echo "3. Iniciando a verificacao completa de virus..."
sudo mkdir -p /tmp/quarentena #³  
sudo clamscan -r / --bell -i --move=/tmp/quarentena 
echo "Verificacao completada"
echo ""

# 4. Verificar se a verificação encontrou ameaças
echo "4. Verifica se a verificacao encontrou ameaças..."
if [ $? -eq 0 ]; then
    echo "Nenhum virus ou ameaca encontrado."
else
    echo "Virus ou ameacas encontradas e movidas para a quarentena em /tmp/quarentena."
fi

#¹ O comando "&>/dev/null" redireciona a saída e os erros de um programa para o arquivo especial "/dev/null", que descarta intencionalmente qualquer dado enviado para ele.
#² A variável "$?" armazena o status de saída do último comando executado.
#³ -p (ou --parents) garante que o comando não gere erros caso o diretório já exista e cria automaticamente os diretórios pai, caso necessário.