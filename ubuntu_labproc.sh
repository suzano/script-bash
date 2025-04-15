#!/bin/bash

################################## DESCRIÇÃO ###################################
# Script Name:  ubuntu_labproc.sh
# Description:  Faz a atualizacao do Ubuntu e limpeza dos pacotes baixados
#               ou desnecessário para o sistema. Prepara o computador para
#		as aulas no LabProc.
# Author: Suzano Bitencourt
# Date: 14/04/2025
# Version: 1.0
# License: GPL-3.0
# Usage: 
#   ./ubuntu_labproc.sh
#
# Requirements:
#   - O script deve ser executado com privilégios de superusuário (root).
#   - O apt é um sistema de gerenciamento de pacotes de programas padrão para 
#     	sistemas operacionais baseados em Debian e Ubuntu. 
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
#   8. Cria usuário com permissão sudo
#   9. Verifica e instala pacotes necessários para as aulas
#   10. Adiciona PATH do LinkServer ao .bashrc do usuário
#   11. Reinicia o sistema
#
# Example:
#   sudo ./ubuntu_labproc.sh
#
# Notes:
#   - Nenhuma observacao ou erro relatado no funcionamento do script.

################################## FORMATAÇÃO ##################################

# Definição de códigos de cores ANSI
H1='\033[1;34m'               # Títulos (Azul)
H2='\033[1;36m'             # Subtítulos (Ciano)
H3='\033[0;36m'           # Subtítulos (Ciano)
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

##################### PACOTES ESPECÍFICOS PARA INSTALAÇÃO ######################

# Programas para instalar via APT (apenas nome do pacote)
APT_PROGRAMS=(
    "wget" # Web Get - usado para baixar arquivos da internet diretamente pelo terminal
    "curl" # Client URL - usado para transferir dados de/para servidores              		
    "git" # Sistema de controle de versão distribuído (DVCS)
    "cmatrix" # Simula o efeito Matrix no terminal
    "sl" # Trem animado (ASCII art) que atravessa o terminal
    "gparted" # GNOME Partition Editor - utilitário gráfico livre para gerenciar partições de disco
    "perl" # Perl é uma família de duas linguagens de programação de alto nível, Perl 5 e Perl 6 (renomeada para Raku)
    "build-essential" # Contém uma coleção de pacotes que são considerados essenciais para compilar software a partir do código-fonte
    "libspreadsheet-writeexcel-perl" # Módulo Perl que permite criar e escrever arquivos no formato binário do Microsoft Excel (.xls)
    "libcurses-perl" # Módulo para a linguagem Perl que fornece uma interface para a biblioteca curses (API que permite criar interfaces de texto interativas (TUI) em ambientes de terminal
    "htop" # Monitor interativo de processos para o terminal
    "neofetch" # Exibe informações do sistema no terminal
    "clamav" # Software antivírus de código aberto utilizado para detectar e eliminar malware, como vírus e trojans
    "cmake" # Ferramenta de build para gerar scripts de compilação
    "ninja-build" # Sistema de build rápido e minimalista
    "gperf" # Gerador de funções hash perfeitas
    "ccache" # Cache para compiladores, acelera recompilações
    "dfu-util" # Ferramenta para atualizar firmware via DFU (Device Firmware Upgrade)
    "device-tree-compiler" # Compilador de Device Tree (arquivos .dts para .dtb)
    "python3-dev" # Arquivos de desenvolvimento para Python 3 (cabeçalhos e bibliotecas)
    "python3-pip" # Gerenciador de pacotes para Python
    "python3-setuptools" # Ferramentas para instalar e gerenciar pacotes Python
    "python3-tk" # Biblioteca Tkinter para interfaces gráficas em Python
    "python3-wheel" # Formato de distribuição para pacotes Python
    "xz-utils" # Utilitários para compactação/descompactação .xz e .lzma
    "file" # Determina o tipo de arquivo usando "magic numbers"
    "make" # Ferramenta para automatizar a compilação de programas
    "gcc" # Compilador C padrão (GNU Compiler Collection).
    "gcc-multilib" # Suporte para compilar para múltiplas arquiteturas (32/64 bits)
    "g++-multilib" # Versão do GCC para C++ com suporte multilib
    "libsdl2-dev" # Biblioteca para desenvolvimento de jogos e multimídia (SDL2)
    "libmagic1t64" # Biblioteca para detecção do tipo de arquivo (usada pelo comando file)
    "python3-venv" # Módulo para criar ambientes virtuais Python isolados
)

# Programas para instalar via DEB (nome do programa + URL do .deb)
declare -A DEB_PROGRAMS=(
    ["google-chrome"]="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    ["balena-etcher"]="https://github.com/balena-io/etcher/releases/download/v2.1.0/balena-etcher_2.1.0_amd64.deb"
    ["textmaker24"]="https://www.freeoffice.com/download.php?filename=https://www.softmaker.net/down/softmaker-freeoffice-2024_1224-01_amd64.deb"
)

# Programas para instalar via Flatpak (nome do pacote Flatpak)
FLATPAK_PROGRAMS=(
    org.geany.Geany # Editor de texto leve e rápido, com recursos de um ambiente de desenvolvimento integrado (IDE) básico
    org.filezillaproject.Filezilla # Cliente FTP (File Transfer Protocol)
    org.gimp.GIMP # GNU Image Manipulation Program - usado para editar imagens
    org.inkscape.Inkscape # Usado para editar e criar gráficos vetoriais
    org.gnucash.GnuCash # Software de finanças pessoais gratuito, de código aberto
    org.videolan.VLC # VLC Media Player é um reprodutor de mídia, áudio e vídeo, além de DVDs e streaming
    com.anydesk.Anydesk # Software proprietário de desktop remoto que permite acessar e controlar um computador remotamente de outro dispositivo
    com.visualstudio.code # Editor de código-fonte leve, porém poderoso, desenvolvido pela Microsoft
    io.github.aandrew_me.ytdn # Ferramenta de linha de comando ou script usado para baixar vídeos do YouTube
    cc.arduino.IDE2 # IDE para desenvolver projetos com Arduino
    com.google.Chrome # Navegador do Google que combina um design minimalista com tecnologia sofisticada
)

# Programas para instalar via Snap (nome do pacote Snap)s
SNAP_PROGRAMS=(
    "asciiquarium"         # Programa de terminal que exibe uma animação de um aquário usando caracteres ASCII 
)

# Programas com instalação personalizada (nome + comandos)
# Cada entrada é um array com o nome do programa seguido dos comandos
declare -A CUSTOM_PROGRAMS=(
    # Docker-CE para Ubuntu 24.04
    ["docker-ce"]="sudo apt-get install -y ca-certificates curl && \
    sudo install -m 0755 -d /etc/apt/keyrings && \
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    sudo chmod a+r /etc/apt/keyrings/docker.asc && \
    echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"${UBUNTU_CODENAME:-$VERSION_CODENAME}\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    sudo apt-get update -y && \
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose docker-compose-plugin && \
    sudo usermod -aG docker $USER && \
    newgrp docker"
)

############################## ADIÇÃO DE USUÁRIOS ##############################

# Configurações do usuário
USERNAME="labproc-pcs"
USER_FULLNAME="LABPROC-PCS"
PASSWORD="PCS"
USER_SHELL="/bin/bash"
USER_GROUPS="sudo"

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
        echo -e "${H2}  Interface:${DEFAULT} $interface"
        # IP e Máscara
        ip_addr=$(ip -4 addr show $interface | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+')
        [ -z "$ip_addr" ] && ip_addr="Não atribuído"
        echo -e "${H3}    IP/Máscara:${DEFAULT} $ip_addr"
        
        # Gateway
        gateway=$(ip route | grep "default via.*$interface" | awk '{print $3}')
        [ -z "$gateway" ] && gateway="Não configurado"
        echo -e "${H3}    Gateway:${DEFAULT} $gateway"
        
        # DNS
        dns=$(grep "nameserver" /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')
        [ -z "$dns" ] && dns="Não configurado"
        echo -e "${H3}    DNS:${DEFAULT} $dns"
        
        # Verifica se a interface tem acesso à internet
        if ip route | grep -q "default via.*$interface"; then
            echo -e "${H3}    Internet:${SUCCESS}Rota padrão${DEFAULT}"
        else
            echo -e "${H3}    Internet:${ERROR}Sem rota padrão${DEFAULT}"
        fi
    done
    echo ""
}

# Atualiza repositórios e pacotes
function update_system() {
    echo -e "${H1}Verificando atualizações do sistema...${DEFAULT}"
    # Atualiza a lista de pacotes disponíveis nos repositórios
    echo -e "${H2}Atualizando lista de pacotes...${DEFAULT}"
    if ! sudo apt update -y > /dev/null 2>&1; then
        echo -e "${ERROR}Falha ao atualizar a lista de pacotes. Verifique a configuração do apt.${DEFAULT}"
        echo ""
        exit 1
        else
            echo -e "${SUCCESS}Lista de pacotes atualizado.${DEFAULT}"
    fi
    # Verifica se há pacotes para atualizar
    if [ "$(apt list --upgradable 2>/dev/null | wc -l)" -gt 1 ]; then
        echo -e "${H2}Instalando atualizações disponíveis...${DEFAULT}"
        sudo apt upgrade -y
        sudo apt autoremove -y  # Remove pacotes não utilizados
        #sudo apt dist-upgrade -y # Atualiza o sistema com todas as atualizações disponíveis, inclusive aquelas que exigem a remoção ou instalação de novos pacotes
        echo -e "${SUCCESS}Sistema atualizado com sucesso.${DEFAULT}"
    else
        echo -e "${ERROR}Erro ao atualizar o sistema. Verifique a configuração ou os pacotes instalados.${DEFAULT}"
    fi
    echo ""
}

# Habilita atualizações automáticas de segurança
function enable_auto_updates() {
    echo -e "${H1}Configurando atualizações automáticas de segurança...${DEFAULT}"

    # Verifica se o pacote 'unattended-upgrades' está instalado
    if ! dpkg -l | grep -q "unattended-upgrades"; then
        echo -e "${H2}Instalando pacote 'unattended-upgrades'...${DEFAULT}"
        sudo apt install -y unattended-upgrades
        echo -e "${SUCCESS}Pacote 'unattended-upgrades' instalado com sucesso.${DEFAULT}"
    fi

    # Habilita atualizações automáticas (modo não interativo)
    echo -e "${H2}Ativando configuração automática...${DEFAULT}"
    sudo dpkg-reconfigure -f noninteractive unattended-upgrades
    echo -e "${SUCCESS}Ativação do 'unattended-upgrades' com sucesso.${DEFAULT}"

    # Verifica se o serviço está ativo
    echo -e "${H2}Verificando se o serviço atualizações automáticas de segurança está ativo...${DEFAULT}"
    if systemctl is-enabled unattended-upgrades > /dev/null 2>&1; then
        echo -e "${SUCCESS}Atualizações automáticas já estão habilitadas.${DEFAULT}"
    else
        sudo systemctl enable unattended-upgrades
        sudo systemctl start unattended-upgrades
        echo -e "${SUCCESS}Atualizações automáticas ativadas com sucesso.${DEFAULT}"
    fi
    echo ""

    # Configura para reiniciar automaticamente se necessário (opcional)
    #echo 'Unattended-Upgrade::Automatic-Reboot "true";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null
    #echo 'Unattended-Upgrade::Automatic-Reboot-Time "03:00";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null
}

# Instala e atualiza programas específicos
## Parte 1 - Função para verificar se um programa está instalado 
function is_installed() {
    local program_name=$1
    # Verifica via apt (para programas instalados com apt/dpkg)
    if apt list --installed 2>/dev/null | grep -q $program_name; then
        return 0
    fi
    # Verifica via dpkg (para programas instalados com apt/dpkg)
    if dpkg -l | grep -q "^ii  $program_name "; then
        return 0
    fi
    # Verifica via which (para programas no PATH)
    if which "$program_name" &>/dev/null; then
        return 0
    fi
    # Verifica via flatpak
    if command -v flatpak &>/dev/null && flatpak list | grep -q "$program_name"; then
        return 0
    fi
    # Verifica via snap
    if command -v snap &>/dev/null && snap list | grep -q "$program_name"; then
        return 0
    fi
    # Se não encontrado em nenhum dos métodos acima
    return 1
}
## Parte 2 - Função para instalar um programa via APT
function install_apt() {
    local program_name=$1
    echo -e "${H3}Instalando $program_name via APT...${DEFAULT}"
    sudo apt install -y "$program_name"
}
Parte 3 - Função para instalar um programa via arquivo .deb
function install_deb() {
    local program_name=$1
    local download_url=$2
    local temp_dir=$(mktemp -d)
    echo -e "${H3}Instalando $program_name via DEB...${DEFAULT}"
    echo -e "${H3}Baixando pacote de $download_url${DEFAULT}"
    # Baixa o arquivo .deb
    if ! wget "$download_url" -P "$temp_dir"; then
        echo -e "${ERROR}Erro ao baixar o arquivo .deb${DEFAULT}"
        rm -rf "$temp_dir"
        return 1
    fi
    # Encontra o arquivo .deb baixado
    local deb_file=$(find "$temp_dir" -name "*.deb" | head -n 1)
    if [[ -z "$deb_file" ]]; then
        echo -e "${ERROR}Erro: Não foi possível encontrar o arquivo .deb baixado${DEFAULT}"
        rm -rf "$temp_dir"
        return 1
    fi
    # Instala o pacote
    if ! sudo dpkg -i "$deb_file"; then
        echo -e "${ERROR}Erro ao instalar o pacote .deb, tentando corrigir dependências...${DEFAULT}"
        sudo apt install -f -y
    fi
    # Limpa o diretório temporário
    rm -rf "$temp_dir"
}
## Parte 4 - Função para instalar um programa via Flatpak
function install_flatpak() {
    local program_name=$1
    echo -e "${H3}Instalando $program_name via Flatpak...${DEFAULT}"
    # Verifica se o Flatpak está instalado
    if ! command -v flatpak &>/dev/null; then
        echo -e "${H3}Flatpak não está instalado. Instalando...${DEFAULT}"
        sudo apt install flatpak -y
        sudo sudo apt install gnome-software-plugin-flatpak
        echo -e "${WARNING}Flatpak foi instalando com sucesso. Para funcionar corretamente, o sistema precisa ser reiniciado...${DEFAULT}"
    fi
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install flathub "$program_name" -y
}
## Parte 5 - Função para instalar um programa via Snap
function install_snap() {
    local program_name=$1
    echo -e "${H3}Instalando $program_name via Snap...${DEFAULT}"
    # Verifica se o Snap está instalado
    if ! command -v snap &>/dev/null; then
        echo -e "${H3}Snap não está instalado. Instalando...${DEFAULT}"
        sudo apt install -y snapd
    fi
    sudo snap install "$program_name"
}
## Parte 6 - Função para instalação personalizada
function install_custom() {
    local program_name=$1
    local install_script=$2  
    echo -e "${H3}Instalando $program_name via comandos personalizados...${DEFAULT}"
    echo -e "${H3}Executando os seguintes comandos:${DEFAULT}"
    # Executa os comandos em um subshell
    (
        eval "$install_script"
    )
    # Verifica se a instalação foi bem-sucedida
    if [[ $? -eq 0 ]]; then
        echo -e "${SUCCESS}$program_name instalado com sucesso!${DEFAULT}"
    else
        echo -e "${ERROR}Falha ao instalar $program_name${DEFAULT}"
        return 1
    fi
}
## Parte Final - Atualiza a lista de pacotes antes de começar
function install_all() {
	echo -e "${H1}Instalando e atualizando programas específicos...${DEFAULT}"
	# Instala programas via APT
	echo -e "${H2}Processando programas APT...${DEFAULT}"
	for program in "${APT_PROGRAMS[@]}"; do
	    echo -e "${H3}Verificando $program...${DEFAULT}"
	    if ! is_installed "$program"; then
		install_apt "$program"
	    else
		echo -e "${SUCCESS}$program já está instalado.${DEFAULT}"
	    fi
	    echo -e "------------------------------------------------------------"
	done
	# Instala programas via DEB
	echo -e "${H2}Processando programas DEB...${DEFAULT}"
	for program in "${!DEB_PROGRAMS[@]}"; do
	    echo -e "${H3}Verificando $program...${DEFAULT}"
	    if ! is_installed "$program"; then
		install_deb "$program" "${DEB_PROGRAMS[$program]}"
	    else
		echo -e "${SUCCESS}$program já está instalado.${DEFAULT}"
	    fi
	    echo -e "------------------------------------------------------------"
	done
	# Instala programas via Flatpak
	echo -e "${H2}Processando programas Flatpak...${DEFAULT}"
	for program in "${FLATPAK_PROGRAMS[@]}"; do
	    echo -e "${H3}Verificando $program...${DEFAULT}"
	    if ! is_installed "$program"; then
		install_flatpak "$program"
	    else
		echo -e "${SUCCESS}$program já está instalado.${DEFAULT}"
	    fi
	    echo -e "------------------------------------------------------------"
	done
	# Instala programas via Snap
	echo -e "${H2}Processando programas Snap...${DEFAULT}"
	for program in "${SNAP_PROGRAMS[@]}"; do
	    # Extrai o nome do programa sem opções (caso tenha --classic etc)
	    program_name=$(echo "$program" | awk '{print $1}')
	    echo -e "${H3}Verificando $program_name...${DEFAULT}"
	    if ! is_installed "$program_name"; then
		install_snap "$program"
	    else
		echo -e "${SUCCESS}$program_name já está instalado.${DEFAULT}"
	    fi
	    echo -e "------------------------------------------------------------"
	done
	# Instala programas com método personalizado
	echo -e "${H2}Processando programas com instalação personalizada...${DEFAULT}"
	for program in "${!CUSTOM_PROGRAMS[@]}"; do
	    echo -e "${H3}Verificando $program...${DEFAULT}"
	    if ! is_installed "$program"; then
		install_custom "$program" "${CUSTOM_PROGRAMS[$program]}"
	    else
		echo -e "${SUCCESS}$program já está instalado.${DEFAULT}"
	    fi
	    echo -e "------------------------------------------------------------"
	done
    echo ""
}

# Limpeza do APT (gerenciador de pacotes)
function clean_apt() {
    echo -e "${H1}Limpando cache do APT...${DEFAULT}"    
    # Remove pacotes baixados
    sudo apt clean
    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}Cache de pacotes limpo com sucesso.${DEFAULT}"
    else
        echo -e "${ERROR}Falha ao limpar o cache de pacotes.${DEFAULT}" >&2
    fi
    # Remove pacotes incompletos
    sudo apt autoclean
    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}Pacotes incompletos removidos com sucesso.${DEFAULT}"
    else
        echo -e "${ERROR}Falha ao remover pacotes incompletos.${DEFAULT}" >&2
    fi
    # Remove dependências não utilizadas
    sudo apt autoremove --purge -y
    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}Dependências não utilizadas removidas com sucesso.${DEFAULT}"
    else
        echo -e "${ERROR}Falha ao remover dependências não utilizadas.${DEFAULT}" >&2
    fi
    # Remove pacotes antigos de kernels não utilizados
    sudo apt purge -y $(dpkg -l | awk '/^ii linux-image-*/{print $2}' | grep -v $(uname -r)) 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}Kernels antigos removidos com sucesso.${DEFAULT}"
    else
        echo -e "${INFO}Nenhum kernel antigo encontrado para remoção.${DEFAULT}" >&2
    fi
    # Limpa arquivos de lock (caso existam)
    sudo rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}Arquivos de lock removidos com sucesso.${DEFAULT}"
    else
        echo -e "${INFO}Nenhum arquivo de lock encontrado.${DEFAULT}" >&2
    fi
    echo ""
}

# Limpeza de arquivos temporários
function clean_tmp() {
    echo -e "${H1}Limpando arquivos temporários...${DEFAULT}"
    # Remove arquivos temporários do sistema
    sudo rm -rf /tmp/*
    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}Arquivos temporários do sistema removidos com sucesso.${DEFAULT}"
    else
        echo -e "${ERROR}Falha ao remover arquivos temporários do sistema.${DEFAULT}" >&2
    fi
    # Remove arquivos temporários do usuário
    rm -rf ~/.cache/*
    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}Arquivos temporários do usuário removidos com sucesso.${DEFAULT}"
    else
        echo -e "${ERROR}Falha ao remover arquivos temporários do usuário.${DEFAULT}" >&2
    fi
    echo ""
}

# Limpeza de cache de aplicativos
function clean_app_cache() {
    echo -e "${H1}Limpando cache de aplicativos...${DEFAULT}"
    # Limpa o cache do navegador Firefox
    if [ -d ~/.mozilla/firefox/ ]; then
        rm -rf ~/.mozilla/firefox/*.default-release/storage/*
        rm -rf ~/.mozilla/firefox/*.default-release/cache2/*
        echo -e "${SUCCESS}Cache do Firefox limpo com sucesso.${DEFAULT}"
    else
        echo -e "${INFO}Firefox não encontrado, pulando limpeza.${DEFAULT}" >&2
    fi
    # Limpa o cache do Chromium/Chrome
    if [ -d ~/.config/chromium/ ]; then
        rm -rf ~/.config/chromium/Default/Cache/*
        rm -rf ~/.config/chromium/Default/Code\ Cache/*
        echo -e "${SUCCESS}Cache do Chromium limpo com sucesso.${DEFAULT}"
    else
        echo -e "${INFO}Chromium não encontrado, pulando limpeza.${DEFAULT}" >&2
    fi
    echo ""
}

# Limpeza de thumbnails
function clean_thumbnails() {
    echo -e "${H1}Limpando thumbnails...${DEFAULT}"
    # Remove thumbnails gerados pelo sistema
    rm -rf ~/.cache/thumbnails/*
    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}Thumbnails removidos com sucesso.${DEFAULT}"
    else
        echo -e "${ERROR}Falha ao remover thumbnails.${DEFAULT}" >&2
    fi
    echo ""
}

# Limpeza de arquivos de log
function clean_logs() {
    echo -e "${H1}Limpando arquivos de log...${DEFAULT}"
    # Remove logs antigos do sistema
    sudo find /var/log -type f -regex ".*\.gz$" -delete
    sudo find /var/log -type f -regex ".*\.[0-9]$" -delete
    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}Logs antigos removidos com sucesso.${DEFAULT}"
    else
        echo -e "${ERROR}Falha ao remover logs antigos.${DEFAULT}" >&2
    fi
    # Limpa arquivos de log do journald
    sudo journalctl --vacuum-time=7d
    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS}Logs do journald limpos com sucesso.${DEFAULT}"
    else
        echo -e "${ERROR}Falha ao limpar logs do journald.${DEFAULT}" >&2
    fi
    echo ""
}

# Limpeza de pacotes Snap antigos
function clean_snap() {
    echo -e "${H1}Limpando pacotes Snap antigos...${DEFAULT}"
    # Remove revisões antigas de pacotes Snap
    if command -v snap &> /dev/null; then
        LANG=C snap list --all | awk '/disabled/{print $1, $3}' | \
        while read snapname revision; do
            sudo snap remove "$snapname" --revision="$revision"
        done
        
        if [ $? -eq 0 ]; then
            echo -e "${SUCCESS}Revisões antigas do Snap removidas com sucesso.${DEFAULT}"
        else
            echo -e "${INFO}Nenhuma revisão antiga do Snap encontrada.${DEFAULT}" >&2
        fi
    else
        echo -e "${INFO}Snap não está instalado, pulando limpeza.${DEFAULT}" >&2
    fi
    echo ""
}

# Criar usuário
create_user() {
    echo -e "${H1}Criando usuário ${USERNAME} no sistema...${DEFAULT}"
    if id "${USERNAME}" &>/dev/null; then
        echo -e "${WARNING}Usuário ${USERNAME} já existe.${DEFAULT}"
    else
        useradd -m -c "${USER_FULLNAME}" -s "${USER_SHELL}" "${USERNAME}"
        echo "${USERNAME}:${PASSWORD}" | chpasswd
        
        # Adiciona aos grupos especificados
        for group in ${USER_GROUPS}; do
            usermod -aG "${group}" "${USERNAME}"
        done
        
        echo -e "${SUCCESS}Usuário ${USERNAME} criado com senha '${PASSWORD}' e adicionado aos grupos: ${USER_GROUPS}.${DEFAULT}"
    fi
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
    # Passo 4. Atualiza repositórios e pacotes
    update_system 
    # Passo 5. Habilita atualizações automáticas de segurança
    enable_auto_updates
    # Passo 6. Instala e atualiza programas específicos
    install_all
    # Passo 7. Limpeza do APT
    clean_apt
    # Passo 8. Limpeza de arquivos temporários
    clean_tmp
    # Passo 9. Limpeza de cache de aplicativos
    clean_app_cache
    # Passo 10. Limpeza de thumbnails
    clean_thumbnails
    # Passo 11. Limpeza de arquivos de log
    clean_logs
    # Passo 12. Limpeza de pacotes Snap antigos
    clean_snap
    # Passo 13. Criar usuário no sistema
    #create_user
    echo ""
}

main  # Inicia o script
