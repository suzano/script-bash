#!/bin/bash

################################################################################
# Script Name:  debian_inventario.sh
# Description:  Gera um relatório detalhado do hardware e software instalados 
#               no sistema e salva em um arquivo ou envia por e-mail.
#               Facilitar a auditoria e o gerenciamento de recursos.
# Author: Suzano Bitencourt
# Date: 20/11/2024
# Version: 1.0
# License: GPL-3.0
# Usage: 
#   ./debian_inventario.sh
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
#   ./debian_inventario.sh
#
# Notes:
#   - Nenhuma observacao ou erro relatado no funcionamento do script.
#
################################################################################

# Configurações
ARQUIVO_RELATORIO="/tmp/relatorio_inventario_$(hostname)_$(date +%Y-%m-%d).txt"
EMAIL_DESTINO="seuemail@exemplo.com"
ASSUNTO="Relatório de Inventário - $(hostname) - $(date)"

# Coletar informações do hardware
echo "Coletando informações do hardware..." > "$ARQUIVO_RELATORIO"
echo "=== Informações do Hardware ===" >> "$ARQUIVO_RELATORIO"
lshw -short >> "$ARQUIVO_RELATORIO" 2>/dev/null || echo "lshw não está instalado." >> "$ARQUIVO_RELATORIO"
echo "" >> "$ARQUIVO_RELATORIO"

# Coletar informações da CPU
echo "=== Informações da CPU ===" >> "$ARQUIVO_RELATORIO"
lscpu >> "$ARQUIVO_RELATORIO"
echo "" >> "$ARQUIVO_RELATORIO"

# Coletar informações de memória
echo "=== Informações de Memória ===" >> "$ARQUIVO_RELATORIO"
free -h >> "$ARQUIVO_RELATORIO"
echo "" >> "$ARQUIVO_RELATORIO"

# Coletar informações de disco
echo "=== Informações do Disco ===" >> "$ARQUIVO_RELATORIO"
df -h >> "$ARQUIVO_RELATORIO"
echo "" >> "$ARQUIVO_RELATORIO"

# Coletar informações de software
echo "=== Informações de Software Instalado ===" >> "$ARQUIVO_RELATORIO"
dpkg-query -l >> "$ARQUIVO_RELATORIO"
echo "" >> "$ARQUIVO_RELATORIO"

# Exibir o relatório no terminal (opcional)
cat "$ARQUIVO_RELATORIO"

# Enviar por e-mail (opcional)
if command -v mail &>/dev/null; then
    echo "Enviando relatório por e-mail..."
    mail -s "$ASSUNTO" "$EMAIL_DESTINO" < "$ARQUIVO_RELATORIO"
    if [ $? -eq 0 ]; then
        echo "E-mail enviado com sucesso para $EMAIL_DESTINO."
    else
        echo "Erro ao enviar o e-mail."
    fi
else
    echo "Comando 'mail' não encontrado. Instale-o para habilitar o envio de e-mails."
fi