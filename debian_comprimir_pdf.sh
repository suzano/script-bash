#!/bin/bash

################################################################################
# Script Name:  debian_comprimir_pdf.sh
# Description:  Comprime arquivos PDF usando o Ghostscript (gs).
# Author: Suzano Bitencourt
# Date: 06/12/2024
# Version: 1.0
# License: GPL-3.0
# Usage: 
#   ./debian_comprimir_pdf.sh
#
# Requirements:
#   - O apt é um sistema de gerenciamento de pacotes de programas padrão para 
#       sistemas operacionais baseados em Debian e Ubuntu. 
#   - Ghostscript instalado (comando `gs`).
#
# Features:
#   1. Verificar se o Ghostscript está instalado
#   2. Verificar se os argumentos foram fornecidos
#   3. Verificar se o arquivo de entrada existe
#   4. Comprimir o PDF usando Ghostscript
#   5. Verificar se a compressão foi bem-sucedida
#
# Example:
#   ./debian_comprimir_pdf.sh
#
# Notes:
#   - Nenhuma observacao ou erro relatado no funcionamento do script.
#
################################################################################

# Verificar se o Ghostscript está instalado
if ! command -v gs &> /dev/null; then
    echo "Erro: O Ghostscript não está instalado. Instale-o com:"
    echo "      sudo apt install ghostscript"
    exit 1
fi

# Verificar se os argumentos foram fornecidos
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <arquivo_entrada.pdf> <arquivo_saida.pdf>"
    exit 1
fi

ARQUIVO_ENTRADA="$1"
ARQUIVO_SAIDA="$2"

# Verificar se o arquivo de entrada existe
if [ ! -f "$ARQUIVO_ENTRADA" ]; then
    echo "Erro: O arquivo de entrada '$ARQUIVO_ENTRADA' não foi encontrado."
    exit 1
fi

# Comprimir o PDF usando Ghostscript
echo "Comprimindo '$ARQUIVO_ENTRADA' para '$ARQUIVO_SAIDA'..."
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook \
   -dNOPAUSE -dQUIET -dBATCH \
   -sOutputFile="$ARQUIVO_SAIDA" "$ARQUIVO_ENTRADA"

# Verificar se a compressão foi bem-sucedida
if [ $? -eq 0 ]; then
    echo "Arquivo comprimido com sucesso: '$ARQUIVO_SAIDA'"
else
    echo "Erro ao comprimir o arquivo. Verifique o arquivo de entrada e tente novamente."
    exit 1
fi