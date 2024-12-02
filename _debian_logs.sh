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

# Diretório de logs do sistema
DIR_LOGS="/var/log"
DIR_ARQUIVOS="/var/backup_logs"

# Dias para considerar logs antigos
DIAS_ANTIGOS=7

# Criar o diretório de backup, se não existir
if [ ! -d "$DIR_ARQUIVOS" ]; then
    mkdir -p "$DIR_ARQUIVOS"
fi

# Compactar logs antigos
echo "Compactando logs antigos (mais de $DIAS_ANTIGOS dias)..."
find "$DIR_LOGS" -type f -mtime +$DIAS_ANTIGOS -name "*.log" -exec tar -rvf "$DIR_ARQUIVOS/logs_antigos_$(date +%Y-%m-%d).tar.gz" {} +

# Verificar se a compactação foi bem-sucedida
if [ $? -eq 0 ]; then
    echo "Compactação concluída com sucesso!"
else
    echo "Erro ao compactar os logs."
    exit 1
fi

# Remover logs antigos após o backup
echo "Removendo logs antigos..."
find "$DIR_LOGS" -type f -mtime +$DIAS_ANTIGOS -name "*.log" -exec rm -f {} +

# Limpar logs rotacionados
echo "Limpando logs rotacionados..."
find "$DIR_LOGS" -type f -name "*.gz" -exec rm -f {} +

# Finalizar
echo "Processo de gerenciamento de logs concluído. Logs antigos armazenados em $DIR_ARQUIVOS."