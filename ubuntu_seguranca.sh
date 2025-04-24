#!/bin/bash

################################################################################
# Script Name:  ubuntu_seguranca.sh
# Description:  Faz a atualizacao do Ubuntu e limpeza dos pacotes baixados
#               ou desnecessário para o sistema.
# Author: Suzano Bitencourt
# Date: 23/04/2025
# Version: 1.0
# License: GPL-3.0
# Usage: 
#   ./ubuntu_seguranca.sh
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
#   sudo ./ubuntu_update.sh
#
# Notes:
#   - Nenhuma observacao ou erro relatado no funcionamento do script.

################################## FORMATAÇÃO ##################################

# Definição de códigos de cores ANSI
H1='\033[1;34m'               # Títulos (Azul)
H2='\033[1;36m  '             # Subtítulos (Ciano)
H3='\033[0;36m    '           # Subtítulos (Ciano)
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

# Definir a porta SSH
SSH_PORT=22125  # Porta desejada pelo usuário

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

# Verifica conexão com a internet
function check_internet() {
    echo -e "${H1}Verificando conectividade com a internet...${DEFAULT}"
    # Testa conexão com um servidor confiável (Google DNS)
    if ping -c 3 8.8.8.8 > /dev/null 2>&1; then
        echo -e "${SUCCESS}Conexão com a internet ativa.${DEFAULT}"
        echo ""
    else
        echo -e "${ERROR}Sem conexão com a internet!${DEFAULT}"
        echo ""
        exit 1  # Encerra o script com código de erro
    fi
}

# Exibe configurações de rede
function show_network_config() {
    echo -e "${H1}Configurações de rede:${DEFAULT}"
    # Obtém todas as interfaces de rede ativas
    interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)
    for interface in $interfaces; do
        echo -e "${H2}Interface:${DEFAULT} $interface"
        # IP e Máscara
        ip_addr=$(ip -4 addr show $interface | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+')
        [ -z "$ip_addr" ] && ip_addr="Não atribuído"
        echo -e "${H3}IP/Máscara:${DEFAULT} $ip_addr"
        
        # Gateway
        gateway=$(ip route | grep "default via.*$interface" | awk '{print $3}')
        [ -z "$gateway" ] && gateway="Não configurado"
        echo -e "${H3}Gateway:${DEFAULT} $gateway"
        
        # DNS
        dns=$(grep "nameserver" /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')
        [ -z "$dns" ] && dns="Não configurado"
        echo -e "${H3}DNS:${DEFAULT} $dns"
        
        # Verifica se a interface tem acesso à internet
        if ip route | grep -q "default via.*$interface"; then
            echo -e "${H3}Internet:${SUCCESS}Rota padrão${DEFAULT}"
        else
            echo -e "${H3}Internet:${ERROR}Sem rota padrão${DEFAULT}"
        fi
    done
    echo ""
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
        else
            user_type="Regular"
        fi
        
        # Grupos do usuário
        groups=$(id -Gn $user)
        primary_group=$(id -gn $user)
        
        # Status da senha
        pass_status=$(passwd -S $user 2>/dev/null | awk '{print $2}')
        case $pass_status in
            "P") pass_info="Senha definida (P)" ;;
            "NP") pass_info="Sem senha (NP)" ;;
            "L") pass_info="Conta bloqueada (L)" ;;
            *) pass_info="Desconhecido" ;;
        esac
        
        # Último login
        last_login=$(last -n 1 $user | head -n 1 | awk '{print $4" "$5" "$6" "$7}')
        [[ -z "$last_login" ]] && last_login="Nunca logou"
        
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
        
        # Verifica MFA
        mfa_status="Não configurado"
        if [[ "$MFA_APP" == "Google-Authenticator" ]]; then
            if [[ -f "$home_dir/.google_authenticator" ]]; then
                mfa_status="Google Authenticator (configurado)"
                mfa_config=$(head -n 1 "$home_dir/.google_authenticator")
                emergency_codes=$(tail -n +2 "$home_dir/.google_authenticator" | wc -l)
                mfa_status+="\n         Códigos de emergência: $emergency_codes restantes"
            fi
        elif [[ "$MFA_APP" == "FreeOTP" ]]; then
            if grep -q "^HOTP.*$user" /etc/users.oath 2>/dev/null; then
                mfa_status="FreeOTP (configurado)"
            fi
        fi
        
        # Verifica se a conta está expirada
        account_expired=$(chage -l $user 2>/dev/null | grep "Account expires" | cut -d: -f2)
        [[ "$account_expired" == *"never"* ]] && account_expired="Nunca expira"
        
        # Exibe as informações
        echo -e "${H3}Tipo:${DEFAULT} $user_type (UID: $uid, GID: $gid)"
        echo -e "${H3}Diretório home:${DEFAULT} $home_dir"
        echo -e "${H3}Shell:${DEFAULT} $shell"
        echo -e "${H3}Grupos:${DEFAULT} $groups (Grupo primário: $primary_group)"
        echo -e "${H3}Status da senha:${DEFAULT} $pass_info"
        echo -e "${H3}Último login:${DEFAULT} $last_login"
        echo -e "${H3}Acesso SSH:${DEFAULT} $ssh_access"
        echo -e "${H3}MFA:${DEFAULT} $mfa_status"
        echo -e "${H3}Expiração da conta:${DEFAULT} $account_expired"
        
        # Verifica se o usuário está no sudoers
        if sudo -l -U $user | grep -q "(ALL : ALL)"; then
            echo -e "${H3}Privilégios:${DEFAULT} ${WARNING}Tem acesso sudo${DEFAULT}"
        fi
        
    done
    echo ""
}

# Funções para Firewall
function show_firewall_info() {
    echo -e "${H1}Informações do Firewall${DEFAULT}"
    
    # Verifica qual firewall está em uso
    if systemctl is-active --quiet ufw; then
        echo -e "${H2}UFW (Uncomplicated Firewall)${DEFAULT}"
        echo -e "${H3}Status:${DEFAULT}"
        ufw status verbose | sed 's/^/  /'
        
        echo -e "\n${H3}Regras detalhadas:${DEFAULT}"
        ufw show raw | sed 's/^/  /'
        
        elif systemctl is-active --quiet firewalld; then
            echo -e "${H2}Firewalld${DEFAULT}"
            echo -e "${H3}Status:${DEFAULT}"
            firewall-cmd --state | sed 's/^/  /'
            
            echo -e "\n${H3}Zonas ativas:${DEFAULT}"
            firewall-cmd --list-all-zones | sed 's/^/  /'
            
        elif command -v iptables &> /dev/null; then
            echo -e "${H2}IPTables${DEFAULT}"
            echo -e "${H3}Regras IPv4:${DEFAULT}"
            iptables -L -n -v --line-numbers | sed 's/^/  /'
            
            echo -e "\n${H3}Regras IPv6:${DEFAULT}"
            ip6tables -L -n -v --line-numbers | sed 's/^/  /'
           
    else
        echo -e "${ERROR}Nenhum firewall ativo detectado!${DEFAULT}"
    fi
    
    # Sugestões de segurança
    echo -e "\n${H2}Sugestões de Segurança:${DEFAULT}"
    echo -e "  ${INFO}1. Limite o acesso SSH apenas a IPs confiáveis${DEFAULT}"
    echo -e "  ${INFO}2. Bloqueie todas as conexões de entrada por padrão${DEFAULT}"
    echo -e "  ${INFO}3. Habilite logging para conexões rejeitadas${DEFAULT}"
    echo -e "  ${INFO}4. Considere usar fail2ban para proteção adicional${DEFAULT}"
    echo -e "  ${INFO}5. Atualize regularmente as regras do firewall${DEFAULT}"
    echo ""
}

function firewall_management_menu() {
    while true; do
        echo -e "${H1}Menu de Gerenciamento de Firewall${DEFAULT}"
        echo "1) Mostrar status do firewall"
        echo "2) Habilitar firewall (UFW)"
        echo "3) Desabilitar firewall (UFW)"
        echo "4) Adicionar regra de permissão"
        echo "5) Adicionar regra de bloqueio"
        echo "6) Listar regras detalhadas"
        echo "7) Voltar ao menu principal"
        echo -n "Escolha uma opção [1-7]: "
        read choice
        
        case $choice in
            1)
                show_firewall_info
                ;;
            2)
                if command -v ufw &> /dev/null; then
                    ufw enable
                    echo -e "${SUCCESS}UFW habilitado com sucesso!${DEFAULT}"
                else
                    echo -e "${ERROR}UFW não está instalado!${DEFAULT}"
                fi
                ;;
            3)
                if command -v ufw &> /dev/null; then
                    ufw disable
                    echo -e "${WARNING}UFW desabilitado!${DEFAULT}"
                else
                    echo -e "${ERROR}UFW não está instalado!${DEFAULT}"
                fi
                ;;
            4)
                echo -n "Digite a porta/protocolo (ex: 22/tcp): "
                read rule
                if command -v ufw &> /dev/null; then
                    ufw allow $rule
                    echo -e "${SUCCESS}Regra adicionada: allow $rule${DEFAULT}"
                else
                    echo -e "${ERROR}UFW não está instalado!${DEFAULT}"
                fi
                ;;
            5)
                echo -n "Digite a porta/protocolo ou IP a bloquear: "
                read rule
                if command -v ufw &> /dev/null; then
                    ufw deny $rule
                    echo -e "${SUCCESS}Regra adicionada: deny $rule${DEFAULT}"
                else
                    echo -e "${ERROR}UFW não está instalado!${DEFAULT}"
                fi
                ;;
            6)
                if command -v ufw &> /dev/null; then
                    ufw status numbered
                else
                    echo -e "${ERROR}UFW não está instalado!${DEFAULT}"
                fi
                ;;
            7)
                break
                ;;
            *)
                echo -e "${ERROR}Opção inválida!${DEFAULT}"
                ;;
        esac
        
        echo -e "\nPressione Enter para continuar..."
        read -r
        clear
    done
}

# Funções para Monitoramento e Auditoria
function show_monitoring_info() {
    echo -e "${H1}Informações de Monitoramento e Auditoria${DEFAULT}"
    
    # Journalctl
    echo -e "${H2}Systemd Journal (journalctl)${DEFAULT}"
    echo -e "${H3}Últimas mensagens importantes:${DEFAULT}"
    journalctl -p 3 -xb --no-pager | head -n 20 | sed 's/^/  /'
    
    # Auditd
    if systemctl is-active --quiet auditd; then
        echo -e "\n${H2}Auditd${DEFAULT}"
        echo -e "${H3}Status:${DEFAULT}"
        systemctl status auditd --no-pager | sed 's/^/  /'
        
        echo -e "\n${H3}Últimos eventos auditados:${DEFAULT}"
        ausearch -m all -ts today | head -n 20 | sed 's/^/  /'
    else
        echo -e "\n${ERROR}Auditd não está ativo!${DEFAULT}"
    fi
    
    # Sugestões
    echo -e "\n${H2}Sugestões de Segurança:${DEFAULT}"
    echo -e "  ${INFO}1. Configure logrotate para gerenciar logs grandes${DEFAULT}"
    echo -e "  ${INFO}2. Monitore regularmente /var/log/auth.log para autenticações${DEFAULT}"
    echo -e "  ${INFO}3. Considere usar um SIEM para análise centralizada de logs${DEFAULT}"
    echo -e "  ${INFO}4. Habilite auditd para auditoria de comandos privilegiados${DEFAULT}"
    echo ""
}

# Funções para Ferramentas de Prevenção
function show_bruteforce_protection_info() {
    echo -e "${H1}Proteção contra Ataques de Força Bruta${DEFAULT}"
    
    # Fail2Ban
    if systemctl is-active --quiet fail2ban; then
        echo -e "${H2}Fail2Ban${DEFAULT}"
        echo -e "${H3}Status:${DEFAULT}"
        fail2ban-client status | sed 's/^/  /'
        
        echo -e "\n${H3}Jails ativos:${DEFAULT}"
        fail2ban-client status | grep "Jail list" | sed 's/^/  /'
        echo ""
        fail2ban-client status sshd | sed 's/^/  /'
    else
        echo -e "${ERROR}Fail2Ban não está ativo!${DEFAULT}"
    fi
    
    # SSH
    echo -e "\n${H2}Configuração do SSH${DEFAULT}"
    echo -e "${H3}Tentativas de login malsucedidas:${DEFAULT}"
    grep "Failed password" /var/log/auth.log | tail -n 5 | sed 's/^/  /'
    
    # Sugestões
    echo -e "\n${H2}Sugestões de Segurança:${DEFAULT}"
    echo -e "  ${INFO}1. Limite tentativas de login no SSH (MaxAuthTries 3)${DEFAULT}"
    echo -e "  ${INFO}2. Implemente autenticação por chaves em vez de senhas${DEFAULT}"
    echo -e "  ${INFO}3. Considere usar port knocking para ocultar portas${DEFAULT}"
    echo -e "  ${INFO}4. Habilite rate limiting no firewall${DEFAULT}"
    echo -e "  ${INFO}5. Monitore logs regularmente para detectar padrões de ataque${DEFAULT}"
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

# Verifica se o SSH está instalado
function check_ssh_installed() {
    echo -e "${H1}Verificando se o OpenSSH está instalado...${DEFAULT}"

    if dpkg -l | grep -q "openssh-server"; then
        echo -e "${SUCCESS}OpenSSH está instalado.${DEFAULT}"
    else
        echo -e "${ERROR}OpenSSH não está instalado!${DEFAULT}"
        echo -e "${WARNING}Instale com: sudo apt install openssh-server${DEFAULT}"
        exit 1
    fi
    echo ""
}

# Verifica e altera a porta do SSH
function configure_ssh_port() {
    echo -e "${H1}Verificando configuração da porta SSH...${DEFAULT}"

    # Obtém a porta atual configurada no arquivo /etc/ssh/sshd_config
    porta_atual=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')

    if [[ "$porta_atual" == "$SSH_PORT" ]]; then
        echo -e "${SUCCESS}O SSH já está configurado para usar a porta ${SSH_PORT}.${DEFAULT}"
    else
        echo -e "${WARNING}O SSH está utilizando a porta $porta_atual. Alterando para ${SSH_PORT}...${DEFAULT}"
        
        # Altera a porta no arquivo de configuração do SSH
        sudo sed -i "s/^Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config
        
        # Reinicia o serviço SSH para aplicar a mudança
        sudo systemctl restart ssh
        
        echo -e "${SUCCESS}A porta do SSH foi alterada para ${SSH_PORT}.${DEFAULT}"
    fi
    echo ""
}

# Verifica e instala os pacotes necessários para MFA
function check_mfa_dependencies() {
    echo -e "${H1}Verificando dependências para ${MFA_APP}...${DEFAULT}"
    
    if [[ "$MFA_APP" == "Google-Authenticator" ]]; then
        echo -e "${INFO}Verificando Google Authenticator...${DEFAULT}"
        if ! dpkg -l | grep -q "libpam-google-authenticator"; then
            echo -e "${WARNING}Pacote libpam-google-authenticator não instalado.${DEFAULT}"
            apt-get update
            apt-get install -y libpam-google-authenticator
            echo -e "${SUCCESS}Google Authenticator instalado com sucesso!${DEFAULT}"
        else
            echo -e "${SUCCESS}Google Authenticator já está instalado.${DEFAULT}"
        fi
    elif [[ "$MFA_APP" == "FreeOTP" ]]; then
        echo -e "${INFO}Verificando FreeOTP...${DEFAULT}"
        if ! dpkg -l | grep -q "libpam-oath"; then
            echo -e "${WARNING}Pacote libpam-oath não instalado.${DEFAULT}"
            apt-get update
            apt-get install -y libpam-oath oathtool
            echo -e "${SUCCESS}FreeOTP instalado com sucesso!${DEFAULT}"
        else
            echo -e "${SUCCESS}FreeOTP já está instalado.${DEFAULT}"
        fi
    else
        echo -e "${ERROR}Aplicativo MFA não reconhecido: ${MFA_APP}${DEFAULT}"
        exit 1
    fi
    echo ""
}

# Configura o MFA para um usuário específico
function configure_mfa_for_user() {
       
    echo -e "${H2}Configurando MFA para o usuário ${MAIN_USER}...${DEFAULT}"
    
    if [[ "$MFA_APP" == "Google-Authenticator" ]]; then
        echo -e "${INFO}Iniciando configuração do Google Authenticator...${DEFAULT}"
        su - ${MAIN_USER} -c "google-authenticator -t -d -f -r 3 -R 30 -w 3 -Q UTF8"
        
        echo -e "${SUCCESS}Configuração do Google Authenticator concluída!${DEFAULT}"
        echo -e "${WARNING}Mostre o QR Code gerado para o usuário ${MAIN_USER} escanear com seu app.${DEFAULT}"
        echo -e "${WARNING}Guarde os códigos de emergência em um local seguro!${DEFAULT}"
        
    elif [[ "$MFA_APP" == "FreeOTP" ]]; then
        echo -e "${INFO}Iniciando configuração do FreeOTP...${DEFAULT}"
        secret=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
        echo "HOTP/T30 ${MAIN_USER} - ${secret}" >> /etc/users.oath
        
        echo -e "${SUCCESS}Configuração do FreeOTP concluída!${DEFAULT}"
        echo -e "${WARNING}Informe ao usuário ${MAIN_USER} o seguinte segredo para configurar no app:${DEFAULT}"
        echo -e "${H3}Segredo: ${secret}${DEFAULT}"
    fi
    echo ""
}

# Configura o SSH para usar MFA
function configure_ssh_for_mfa() {
    echo -e "${H1}Configurando SSH para usar ${MFA_APP}...${DEFAULT}"
    
    # Backup do arquivo de configuração
    cp /etc/pam.d/sshd /etc/pam.d/sshd.bak
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    
    if [[ "$MFA_APP" == "Google-Authenticator" ]]; then
        echo -e "${INFO}Configurando PAM para Google Authenticator...${DEFAULT}"
        echo "auth required pam_google_authenticator.so" >> /etc/pam.d/sshd
        
    elif [[ "$MFA_APP" == "FreeOTP" ]]; then
        echo -e "${INFO}Configurando PAM para FreeOTP...${DEFAULT}"
        echo "auth required pam_oath.so usersfile=/etc/users.oath window=30" >> /etc/pam.d/sshd
    fi
    
    # Configuração do SSH
    sed -i 's/^ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
    echo "AuthenticationMethods publickey,keyboard-interactive" >> /etc/ssh/sshd_config
    
    # Reinicia o serviço SSH
    systemctl restart sshd
    
    echo -e "${SUCCESS}SSH configurado para usar ${MFA_APP}!${DEFAULT}"
    echo ""
}

# Aplica MFA para todos os usuários com acesso SSH
function enforce_mfa_for_all_users() {
    echo -e "${H1}Aplicando MFA para todos os usuários...${DEFAULT}"
    
    # Obtém todos os usuários com shell de login
    users=$(getent passwd | grep -v /bin/false | grep -v /usr/sbin/nologin | cut -d: -f1)
    
    for user in $users; do
        # Ignora usuários do sistema
        if [[ $user != "root" && $user != "nobody" && $user != "sync" ]]; then
            echo -e "${INFO}Configurando MFA para o usuário: $user${DEFAULT}"
            configure_mfa_for_user $user
        fi
    done
    
    echo -e "${SUCCESS}MFA aplicado para todos os usuários com acesso SSH!${DEFAULT}"
    echo -e "${WARNING}Certifique-se de que cada usuário configurou seu app MFA corretamente.${DEFAULT}"
    echo ""
}

# Menu para seleção do aplicativo MFA
function select_mfa_app() {
    echo -e "${H1}Seleção do Aplicativo de Autenticação Multifator${DEFAULT}"
    echo "1) Google Authenticator"
    echo "2) FreeOTP"
    echo -n "Escolha o aplicativo MFA [1-2]: "
    read choice
    
    case $choice in
        1) MFA_APP="Google-Authenticator" ;;
        2) MFA_APP="FreeOTP" ;;
        *) 
            echo -e "${ERROR}Opção inválida! Usando Google Authenticator como padrão.${DEFAULT}"
            MFA_APP="Google-Authenticator"
            ;;
    esac
    
    echo -e "${SUCCESS}Aplicativo MFA selecionado: ${MFA_APP}${DEFAULT}"
    echo ""
}



############################## EXECUÇÃO PRINCIPAL ##############################
clear
function main() {
    # Passo 1. Certifica execução do script como root
    check_root
    # Passo 2. Verifica conexão com a internet
    check_internet
    # Passo 3. Exibe configurações de rede
    show_network_config
    # Função para mostrar informações detalhadas dos usuários
    show_user_info
    # Funções para Firewall
    show_firewall_info
    # Funções para Monitoramento e Auditoria
    show_monitoring_info
    # Funções para Ferramentas de Prevenção
    show_bruteforce_protection_info

    # Menu de gerenciamento de usuários
    #user_management_menu
    # Verifica se o SSH está instalado
    #check_ssh_installed
    # Verifica e altera a porta do SSH
    #configure_ssh_port
    # Verifica e instala os pacotes necessários para MFA
    #check_mfa_dependencies
    # Configura o MFA para um usuário específico
    #configure_mfa_for_user
    # Configura o SSH para usar MFA
    #configure_ssh_for_mfa
    # Aplica MFA para todos os usuários com acesso SSH
    #enforce_mfa_for_all_users

}

main  # Inicia o script