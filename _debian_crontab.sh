#!/bin/bash

################################################################################
# Script Name:  debian_crontab.sh
# Description:  Script interativo para gerenciar tarefas no crontab, permitindo
#               listar, adicionar, editar e remover tarefas agendadas.
# Author: Suzano Bitencourt
# Date: 20/11/2024
# Version: 1.0
# License: GPL-3.0
# Usage: 
#   ./debian_crontab.sh
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
#   ./debian_crontab.sh
#
# Notes:
#   - Nenhuma observacao ou erro relatado no funcionamento do script.
#
################################################################################

# Função para exibir o menu principal
exibir_menu() {
    echo "==================================="
    echo "     GERENCIADOR DE CRONTAB        "
    echo "==================================="
    echo "1. Listar tarefas agendadas"
    echo "2. Adicionar uma nova tarefa"
    echo "3. Editar uma tarefa existente"
    echo "4. Remover uma tarefa"
    echo "5. Sair"
    echo "==================================="
}

# Função para listar tarefas do crontab
listar_tarefas() {
    echo "Tarefas atualmente agendadas no crontab:"
    crontab -l | nl
    echo "==================================="
}

# Função para adicionar uma nova tarefa
adicionar_tarefa() {
    echo "Adicionar uma nova tarefa ao crontab"
    read -p "Digite a descrição da tarefa: " descricao
    read -p "Digite o minuto (0-59): " minuto
    read -p "Digite a hora (0-23): " hora
    read -p "Digite o dia do mês (1-31 ou * para todos): " dia_mes
    read -p "Digite o mês (1-12 ou * para todos): " mes
    read -p "Digite o dia da semana (0-7, sendo 0/7 = domingo ou * para todos): " dia_semana
    read -p "Digite o comando a ser executado: " comando

    # Adiciona a tarefa ao crontab
    (crontab -l; echo "$minuto $hora $dia_mes $mes $dia_semana $comando # $descricao") | crontab -
    echo "Tarefa adicionada com sucesso!"
}

# Função para editar uma tarefa existente
editar_tarefa() {
    listar_tarefas
    read -p "Digite o número da tarefa que deseja editar: " numero
    tarefas=$(crontab -l)
    tarefa=$(echo "$tarefas" | sed -n "${numero}p")
    if [ -z "$tarefa" ]; then
        echo "Número de tarefa inválido!"
        return
    fi
    echo "Editando a tarefa: $tarefa"
    read -p "Digite os novos valores (ou pressione ENTER para manter o atual)"
    read -p "Minuto (atual: $(echo $tarefa | awk '{print $1}')): " minuto
    read -p "Hora (atual: $(echo $tarefa | awk '{print $2}')): " hora
    read -p "Dia do mês (atual: $(echo $tarefa | awk '{print $3}')): " dia_mes
    read -p "Mês (atual: $(echo $tarefa | awk '{print $4}')): " mes
    read -p "Dia da semana (atual: $(echo $tarefa | awk '{print $5}')): " dia_semana
    read -p "Comando (atual: $(echo $tarefa | awk '{$1=$2=$3=$4=$5=""; print $0}')): " comando

    # Substituir valores vazios pelos valores atuais
    minuto=${minuto:-$(echo $tarefa | awk '{print $1}')}
    hora=${hora:-$(echo $tarefa | awk '{print $2}')}
    dia_mes=${dia_mes:-$(echo $tarefa | awk '{print $3}')}
    mes=${mes:-$(echo $tarefa | awk '{print $4}')}
    dia_semana=${dia_semana:-$(echo $tarefa | awk '{print $5}')}
    comando=${comando:-$(echo $tarefa | awk '{$1=$2=$3=$4=$5=""; print $0}')}

    # Atualizar a tarefa no crontab
    novo_crontab=$(echo "$tarefas" | sed "${numero}d")
    novo_crontab=$(echo -e "${novo_crontab}\n$minuto $hora $dia_mes $mes $dia_semana $comando")
    echo "$novo_crontab" | crontab -
    echo "Tarefa editada com sucesso!"
}

# Função para remover uma tarefa
remover_tarefa() {
    listar_tarefas
    read -p "Digite o número da tarefa que deseja remover: " numero
    tarefas=$(crontab -l)
    if [ -z "$(echo "$tarefas" | sed -n "${numero}p")" ]; then
        echo "Número de tarefa inválido!"
        return
    fi
    novo_crontab=$(echo "$tarefas" | sed "${numero}d")
    echo "$novo_crontab" | crontab -
    echo "Tarefa removida com sucesso!"
}

# Loop principal do script
while true; do
    exibir_menu
    read -p "Escolha uma opção: " opcao
    case $opcao in
        1) listar_tarefas ;;
        2) adicionar_tarefa ;;
        3) editar_tarefa ;;
        4) remover_tarefa ;;
        5) echo "Saindo..."; exit 0 ;;
        *) echo "Opção inválida! Tente novamente." ;;
    esac
done