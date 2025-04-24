#!/bin/bash

################################################################################
# Script Name:  ubuntu_seguranca_usuarios.sh
# Description:  Faz a atualizacao do Ubuntu e limpeza dos pacotes baixados
#               ou desnecessário para o sistema.
# Author: Suzano Bitencourt
# Date: 23/04/2025
# Version: 1.0
# License: GPL-3.0
# Usage: 
#   ./ubuntu_seguranca_usuarios.sh
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
#   5. Instala e atualiza programas específicos
#   6. Remove pacotes baixados pelo APT
#   7. Remove pacotes que não tiveram seu download concluído
#   8. Remove dependências que não são mais necessárias pelo sistema
#   9. Reinicia o sistema
#
# Example:
#   sudo ./ubuntu_seguranca_usuarios.sh
#
# Notes:
#   - Nenhuma observacao ou erro relatado no funcionamento do script.

################################## FORMATAÇÃO ##################################

# Definição de códigos de cores ANSI
H1='\033[1;34m'               # Títulos (Azul) - Nível 1
H2='\033[1;36m  '             # Subtítulos (Ciano) - Nível 2 (2 espaços)
H3='\033[0;36m    '           # Subtítulos (Ciano) - Nível 3 (4 espaços)
H4='\033[0;35m      '         # Roxo claro - Nível 4 (6 espaços)
H5='\033[0;35m        '       # Roxo - Nível 5 (8 espaços)
H6='\033[0;37m          '     # Cinza claro - Nível 6 (10 espaços)
DEFAULT='\033[0m'             # Cor padrão

# Ícones simples
SUCCESS='\033[0;32m[\u2714] ' # Sucesso (Verde) SIMPLES
ERROR='\033[0;31m[\u2718] '   # Erro (Vermelho) SIMPLES
WARNING='\033[0;33m[\u2691] ' # Aviso (Amarelo) SIMPLES
INFO='\033[0;33m[*] '         # Informação (Amarelo)

# Ícones coloridos
#SUCCESS='\033[0;32m\u2705 '  # Sucesso (Verde) COLORIDO
#ERROR='\033[0;31m\u26D4 '    # Erro (Vermelho) COLORIDO
#WARNING='\033[0;33m\u23F3 '  # Aviso (Amarelo) COLORIDO
#INFO='\033[0;33m[*] '        # Informação (Amarelo)

# Ícones quadrados
#SUCCESS='\033[0;32m\u2611 '  # Sucesso (Verde) QUADRADO
#ERROR='\033[0;31m\u2612 '    # Erro (Vermelho) QUADRADO
#WARNING='\033[0;33m\u2610 '  # Aviso (Amarelo) QUADRADO
#INFO='\033[0;33m[*] '        # Informação (Amarelo)

# Ícones caracter
#SUCCESS='\033[0;32m[+] '     # Sucesso (Verde)
#ERROR='\033[0;31m[-] '       # Erro (Vermelho)
#WARNING='\033[0;33m[!] '     # Aviso (Amarelo)
#INFO='\033[0;33m[*] '        # Informação (Amarelo)

# Ícones escrito
#SUCCESS='\033[0;32m[SUCESSO] '	# Sucesso (Verde)
#ERROR='\033[0;31m[ERRO] '      # Erro (Vermelho)
#WARNING='\033[0;33m[AVISO] '   # Aviso (Amarelo)
#INFO='\033[0;33m[INFO] '       # Informação (Amarelo)

################################ CONFIGURAÇÕES #################################

# Usuário específico
#MAIN_USER="suzano"

# Definir aplicativo de MFA (Google-Authenticator ou FreeOTP)
#MFA_APP="Google-Authenticator"  # Valor padrão

################################### FUNÇÕES ####################################

# Confirma execução do script como root
function check_root() {
    # Verifica se o UID (User ID) do usuário é 0 (root)
    echo -e "${H1}Confirmando a execução do script com permissões de root...${DEFAULT}"
    # Em sistemas Linux, o root sempre tem UID=0
    if [[ $EUID -ne 0 ]]; then
        echo -e "${ERROR}Este script deve ser executado como root!${DEFAULT}"  # Mensagem em vermelho
        #echo -e "${WARNING} Use o comando 'sudo ./$(basename "$0")' ou logue como 'root'.${DEFAULT}"  # Sugestão em amarelo
        echo ""
        exit 1  # Encerra o script com código de erro
    else
        echo -e "${SUCCESS}Privilégios de root detectados.${DEFAULT}"  # Mensagem em verde
        echo ""
    fi
}

# Função para mostrar informações detalhadas dos usuários
function show_user_info() {
    echo -e "${H1}Informações Detalhadas dos Usuários${DEFAULT}"
    
    # Obtém todos os usuários com shell de login (exclui nologin e false)
    users=$(getent passwd | grep -v -e "/bin/false" -e "/usr/sbin/nologin" | cut -d: -f1 | sort)
    
    for user in $users; do
        echo -e "${H2}Usuário:${DEFAULT} $user"
        
        # Informações básicas do usuário
        user_entry=$(getent passwd $user)
        uid=$(echo $user_entry | cut -d: -f3)
        gid=$(echo $user_entry | cut -d: -f4)
        home_dir=$(echo $user_entry | cut -d: -f6)
        shell=$(echo $user_entry | cut -d: -f7)
        
        # Verifica se é usuário do sistema
        if [[ $uid -lt 1000 ]] && [[ $user != "root" ]]; then
            user_type="Sistema" 
            # Sistema - Criado automaticamente pelo sistema ou durante a instalação de pacotes para executar serviços/daemons específicos.
        else
            user_type="Regular" 
            # Regular - Criados manualmente por administradores ou durante a instalação do sistema para usuários humanos.
        fi
        
        echo -e "${H3}Tipo:${DEFAULT} $user_type (UID: $uid, GID: $gid)"
        
        # Diretório home
        echo -e "  ${H3}Diretório home:${DEFAULT} $home_dir"
                
        # Shell
        echo -e "  ${H3}Shell:${DEFAULT} $shell"
                
        # Grupos do usuário
        groups=$(id -Gn $user)
        primary_group=$(id -gn $user)
        echo -e "  ${H3}Grupos:${DEFAULT} $groups (Grupo primário: $primary_group)"
        
        # Status da senha
        pass_status=$(passwd -S $user 2>/dev/null | awk '{print $2}')
        case $pass_status in
            "P") pass_info="Senha definida (P)" ;;
            "NP") pass_info="Sem senha (NP)" ;;
            "L") pass_info="Conta bloqueada (L)" ;;
            *) pass_info="Desconhecido" ;;
        esac
        echo -e "  ${H3}Status da senha:${DEFAULT} $pass_info"
        
        # Último login
        last_login=$(last -n 1 $user | head -n 1 | awk '{print $4" "$5" "$6" "$7}')
        [[ -z "$last_login" ]] && last_login="Nunca logou"
        echo -e "  ${H3}Último login:${DEFAULT} $last_login"
        
        # Verifica acesso SSH
        ssh_access="Não"
        if [[ -f /etc/ssh/sshd_config ]]; then
            if grep -q "^AllowUsers" /etc/ssh/sshd_config; then
                if grep -q "^AllowUsers.*\<$user\>" /etc/ssh/sshd_config; then
                    ssh_access="Sim (explicitamente permitido)"
                fi
            else
                ssh_access="Sim (padrão - nenhuma restrição)"
            fi
            
            if grep -q "^DenyUsers.*\<$user\>" /etc/ssh/sshd_config; then
                ssh_access="Não (explicitamente negado)"
            fi
        fi
        echo -e "  ${H3}Acesso SSH:${DEFAULT} $ssh_access"
                
        # Verifica MFA
        mfa_status="Não configurado"
        if [[ "$MFA_APP" == "Google-Authenticator" ]]; then
            if [[ -f "$home_dir/.google_authenticator" ]]; then
                mfa_status="Google Authenticator (configurado)"
            fi
        elif [[ "$MFA_APP" == "FreeOTP" ]]; then
            if grep -q "^HOTP.*$user" /etc/users.oath 2>/dev/null; then
                mfa_status="FreeOTP (configurado)"
            fi
        fi
        echo -e "  ${H3}MFA:${DEFAULT} $mfa_status"
            
        # Verifica se a conta está expirada
        account_expired=$(chage -l $user 2>/dev/null | grep "Account expires" | cut -d: -f2)
        [[ "$account_expired" == *"never"* ]] && account_expired="Nunca expira"
        echo -e "  ${H3}Expiração da conta:${DEFAULT} $account_expired"
        
        # Verifica se o usuário está no sudoers
        if sudo -l -U $user | grep -q "(ALL : ALL)"; then
            echo -e "  ${H3}Privilégios:${DEFAULT} ${WARNING}Tem acesso sudo${DEFAULT}"
        else
            echo -e "  ${H3}Privilégios:${DEFAULT} Nenhum acesso sudo"
        fi
        
        # Espaçamento entre usuários
        echo ""
    done

    echo -e "${H2}${WARNING}Comandos úteis${DEFAULT}"
    echo -e "${H3}Usuário:${DEFAULT} Conta de usuário"
        echo -e "${H4}Adicionar usuário:${DEFAULT} adduser <nome_do_usuário>"
        echo -e "${H4}Adicionar usuário:${DEFAULT} userdel -r <nome_do_usuário>"
    echo -e "${H3}Diretório home:${DEFAULT} Pasta do usuário"
        echo -e "${H4}Alterar diretório home:${DEFAULT} usermod -d /novo/diretorio -m <nome_do_usuário>"
    echo -e "${H3}Shell:${DEFAULT} $shell"
        echo -e "${H4}Alterar shell:${DEFAULT} usermod -s /bin/novo_shell <nome_do_usuário>"
    echo -e "${H3}Grupos:${DEFAULT} Grupos do usuário"
        echo -e "${H4}Adicionar no grupo:${DEFAULT} usermod -aG <nome_do_grupo> <nome_do_usuário>"
        echo -e "${H4}Remover do grupo:${DEFAULT} gpasswd -d <nome_do_usuário> <nome_do_grupo>"
    echo -e "${H3}Status da senha:${DEFAULT} Status da conta e senha"
        echo -e "${H4}Alterar senha:${DEFAULT} passwd <nome_do_usuário>"
        echo -e "${H4}Remover senha:${DEFAULT} passwd -d <nome_do_usuário>"
        echo -e "${H4}Bloquear conta:${DEFAULT} usermod -L <nome_do_usuário>"
        echo -e "${H4}Desbloquear conta:${DEFAULT} usermod -U <nome_do_usuário>"
    echo -e "${H3}Acesso SSH:${DEFAULT} Permissão de acesso SSH"
        echo -e "${H4}Permitir acesso SSH:${DEFAULT} editar /etc/ssh/sshd_config e adicionar 'AllowUsers <nome_do_usuário>'"
        echo -e "${H4}Bloquear acesso SSH:${DEFAULT} editar /etc/ssh/sshd_config e adicionar 'DenyUsers <nome_do_usuário>'"
    echo -e "${H3}MFA:${DEFAULT} Autenticação Multifator"
        echo -e "${H4}Adicionar MFA:${DEFAULT} sudo -u $user google-authenticator (para Google Authenticator)"
        echo -e "${H4}Remover MFA:${DEFAULT} rm $home_dir/.google_authenticator (para Google Authenticator)"
    echo -e "${H3}Expiração da conta:${DEFAULT} Data de validade"
        echo -e "${H4}Adicionar data de expiração:${DEFAULT} usermod -e YYYY-MM-DD <nome_do_usuário>"
        echo -e "${H4}Remover data de expiração:${DEFAULT} usermod -e \"\" <nome_do_usuário>"
    echo -e "${H3}Privilégios:${DEFAULT} Acesso sudo"
        echo -e "${H4}Adicionar privilégio:${DEFAULT} usermod -aG sudo <nome_do_usuário>"
        echo -e "${H4}Remover privilégio:${DEFAULT} deluser <nome_do_usuário> sudo"
    echo ""    
}

# Menu de gerenciamento de usuários
function user_management_menu() {
    while true; do
        echo -e "${H1}Menu de Gerenciamento de Usuários${DEFAULT}"
        echo "1) Listar informações detalhadas dos usuários"
        echo "2) Adicionar usuário"
        echo "3) Remover usuário"
        echo "4) Alterar senha de usuário"
        echo "5) Adicionar usuário a um grupo"
        echo "6) Remover usuário de um grupo"
        echo "7) Retorna ao fluxo principal"
        echo "8) Sair"
        echo -n "Escolha uma opção [1-8]: "
        read choice
        
        case $choice in
            1)
                show_user_info
                ;;
            2)
                echo -n "Digite o nome do novo usuário: "
                read new_user
                if [[ -z "$new_user" ]]; then
                    echo -e "${ERROR}Nome de usuário não pode ser vazio!${DEFAULT}"
                else
                    if adduser "$new_user" 2>/dev/null; then
                        echo -e "${SUCCESS}Usuário $new_user criado com sucesso!${DEFAULT}"
                    else
                        echo -e "${ERROR}Falha ao criar usuário $new_user${DEFAULT}"
                    fi
                fi
                ;;
            3)
                echo -n "Digite o nome do usuário a ser removido: "
                read del_user
                if id "$del_user" &>/dev/null; then
                    if userdel -r "$del_user" 2>/dev/null; then
                        echo -e "${SUCCESS}Usuário $del_user removido com sucesso!${DEFAULT}"
                    else
                        echo -e "${ERROR}Falha ao remover usuário $del_user${DEFAULT}"
                    fi
                else
                    echo -e "${ERROR}Usuário $del_user não existe!${DEFAULT}"
                fi
                ;;
            4)
                echo -n "Digite o nome do usuário para alterar a senha: "
                read pass_user
                if id "$pass_user" &>/dev/null; then
                    passwd "$pass_user"
                else
                    echo -e "${ERROR}Usuário $pass_user não existe!${DEFAULT}"
                fi
                ;;
            5)
                echo -n "Digite o nome do usuário: "
                read user_name
                echo -n "Digite o nome do grupo: "
                read group_name
                if id "$user_name" &>/dev/null && grep -q "^$group_name:" /etc/group; then
                    if usermod -aG "$group_name" "$user_name"; then
                        echo -e "${SUCCESS}Usuário $user_name adicionado ao grupo $group_name com sucesso!${DEFAULT}"
                    else
                        echo -e "${ERROR}Falha ao adicionar usuário ao grupo${DEFAULT}"
                    fi
                else
                    echo -e "${ERROR}Usuário ou grupo não existe!${DEFAULT}"
                fi
                ;;
            6)
                echo -n "Digite o nome do usuário: "
                read user_name
                echo -n "Digite o nome do grupo: "
                read group_name
                if id "$user_name" &>/dev/null && grep -q "^$group_name:" /etc/group; then
                    if gpasswd -d "$user_name" "$group_name"; then
                        echo -e "${SUCCESS}Usuário $user_name removido do grupo $group_name com sucesso!${DEFAULT}"
                    else
                        echo -e "${ERROR}Falha ao remover usuário do grupo${DEFAULT}"
                    fi
                else
                    echo -e "${ERROR}Usuário ou grupo não existe!${DEFAULT}"
                fi
                ;;
            7)
                # Retorna ao fluxo principal do script
                return 0
                ;;
            8)
                echo -e "${SUCCESS}Saindo do script...${DEFAULT}"
                exit 0
                ;;
            *)
                echo -e "${ERROR}Opção inválida! Por favor, escolha uma opção de 1 a 8.${DEFAULT}"
                ;;
        esac
        
        # Pausa para visualização antes de limpar a tela
        echo -e "\nPressione Enter para continuar..."
        read -r
        clear
    done
}

############################## EXECUÇÃO PRINCIPAL ##############################
clear
function main() {
    # Passo 1. Certifica execução do script como root
    check_root
    # Passo 2. Verifica conexão com a internet
    check_internet
    # Passo 3. Função para mostrar informações detalhadas dos usuários
    show_user_info
    # Passo 4. Menu de gerenciamento de usuários
    #user_management_menu
}

main  # Inicia o script