#!/bin/bash

################################################################################
# Script Name:  debian_backup.sh
# Description:  Faz backup de um ou mais diretórios para um local específico 
#               ou para a nuvem, compactando os arquivos e registrando logs.
#               Garantir a segurança dos dados importantes no laboratório ou
#               servidores.
# Author: Suzano Bitencourt
# Date: 20/11/2024
# Version: 1.0
# License: GPL-3.0
# Usage: 
#   ./debian_backup.sh
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
#   ./debian_backup.sh
#
# Notes:
#   - Nenhuma observacao ou erro relatado no funcionamento do script.
#
################################################################################

# Diretórios a serem incluídos no backup
ORIGENS=("/caminho/diretorio1" "/caminho/diretorio2")

# Diretório de destino para o backup
DESTINO="/caminho/backup"

# Nome do arquivo de backup com a data
DATA=$(date +'%Y-%m-%d')
ARQUIVO_BACKUP="backup_$DATA.tar.gz"

# Criar o diretório de destino, se não existir
if [ ! -d "$DESTINO" ]; then
    mkdir -p "$DESTINO"
fi

# Compactar e criar o backup
echo "Iniciando o backup..."
tar -czf "$DESTINO/$ARQUIVO_BACKUP" "${ORIGENS[@]}"
if [ $? -eq 0 ]; then
    echo "Backup concluído com sucesso! Arquivo salvo em: $DESTINO/$ARQUIVO_BACKUP"
else
    echo "Erro ao criar o backup."
    exit 1
fi

# Registro no log
LOG_FILE="/var/log/backup.log"
echo "$(date) - Backup realizado: $ARQUIVO_BACKUP" >> "$LOG_FILE"