#!/bin/bash

################################################################################
# Script Name:  debian_update.sh
# Description:  Faz a atualizacao do Debian e limpeza dos pacotes baixados
#               ou desnecessário para o sistema.
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
#   sudo ./debian_update.sh
#
# Notes:
#   - Nenhuma observacao ou erro relatado no funcionamento do script.
#
################################################################################

# Definição de códigos de cores ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
DEFAULT='\033[0m' # Reset para a cor padrão

# 0. Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Erro: Este script deve ser executado como root.${DEFAULT}"
    exit 1
fi

# 1. Verifica se existe conexao com a internet
clear
echo -e "${YELLOW}${BOLD}1. Verificando conexão com a Internet...${DEFAULT}"
ping -c 2 google.com &> /dev/null #¹
if [ $? -eq 0 ]; then #²
    echo -e "${CYAN}Conexão com a Internet estável.${DEFAULT}"
else
    echo -e "${RED}Sem conexão com a Internet. Verifique a rede e tente novamente.${DEFAULT}"
    exit 1
fi
echo ""

# 2. Atualiza o repositorio
echo -e "${YELLOW}${BOLD}2. Atualizando repositórios...${DEFAULT}"
sudo apt update -y
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao atualizar repositórios. Verifique a configuração do apt.${DEFAULT}"
    exit 1
else
    echo -e "${CYAN}Repositórios atualizados com sucesso.${DEFAULT}"
fi
echo ""

# 3. Repara pacotes quebrados
echo -e "${YELLOW}${BOLD}3. Reparando pacotes quebrados...${DEFAULT}"
sudo dpkg --configure -a
sudo apt --fix-broken install
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao reparar pacotes quebrados. Tente usar o comando: sudo dpkg --force-remove-reinstreq --remove <pacote>.${DEFAULT}"
    exit 1
else
    echo -e "${CYAN}Pacotes quebrados reparados com sucesso.${DEFAULT}"
fi
echo ""

# 4. Atualiza o sistema
echo -e "${YELLOW}${BOLD}4. Atualizando o sistema...${DEFAULT}"
sudo apt upgrade -y
# sudo apt dist-upgrade -y
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao atualizar o sistema. Verifique a configuração ou os pacotes instalados.${DEFAULT}"
    exit 1
else
    echo -e "${CYAN}Sistema atualizado com sucesso.${DEFAULT}"
fi
echo ""

# 5 - Instala e atualiza programas específicos
# Função para verificar se um programa está instalado 
# Retorna 0 se instalado, 1 caso contrário
function is_installed() {
    local program_name=$1
    
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

# Função para instalar um programa via APT
function install_apt() {
    local program_name=$1
    echo -e "${GREEN}Instalando $program_name via APT...${DEFAULT}"
    sudo apt install -y "$program_name"
}

# Função para instalar um programa via arquivo .deb
function install_deb() {
    local program_name=$1
    local download_url=$2
    local temp_dir=$(mktemp -d)
    
    echo -e "${GREEN}Instalando $program_name via DEB...${DEFAULT}"
    echo -e "${GREEN}Baixando pacote de $download_url${DEFAULT}"
    
    # Baixa o arquivo .deb
    if ! wget "$download_url" -P "$temp_dir"; then
        echo -e "${RED}Erro ao baixar o arquivo .deb${DEFAULT}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Encontra o arquivo .deb baixado
    local deb_file=$(find "$temp_dir" -name "*.deb" | head -n 1)
    
    if [[ -z "$deb_file" ]]; then
        echo -e "${RED}Erro: Não foi possível encontrar o arquivo .deb baixado${DEFAULT}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Instala o pacote
    if ! sudo dpkg -i "$deb_file"; then
        echo -e "${RED}Erro ao instalar o pacote .deb, tentando corrigir dependências...${DEFAULT}"
        sudo apt install -f -y
    fi
    
    # Limpa o diretório temporário
    rm -rf "$temp_dir"
}

# Função para instalar um programa via Flatpak
function install_flatpak() {
    local program_name=$1
    echo -e "${GREEN}Instalando $program_name via Flatpak...${DEFAULT}"
    
    # Verifica se o Flatpak está instalado
    if ! command -v flatpak &>/dev/null; then
        echo -e "${GREEN}Flatpak não está instalado. Instalando...${DEFAULT}"
        sudo apt install -y flatpak
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
    
    flatpak install flathub "$program_name" -y
}

# Função para instalar um programa via Snap
function install_snap() {
    local program_name=$1
    echo -e "${GREEN}Instalando $program_name via Snap...${DEFAULT}"
    
    # Verifica se o Snap está instalado
    if ! command -v snap &>/dev/null; then
        echo -e "${GREEN}Snap não está instalado. Instalando...${DEFAULT}"
        sudo apt install -y snapd
    fi
    
    sudo snap install "$program_name"
}

# Função para instalação personalizada
function install_custom() {
    local program_name=$1
    local install_script=$2
        
    echo -e "${GREEN}Instalando $program_name via comandos personalizados...${DEFAULT}"
    echo -e "${GREEN}Executando os seguintes comandos:${DEFAULT}"
        
    # Executa os comandos em um subshell
    (
        eval "$install_script"
    )
    
    # Verifica se a instalação foi bem-sucedida
    if [[ $? -eq 0 ]]; then
        echo -e "${CYAN}$program_name instalado com sucesso!${DEFAULT}"
    else
        echo -e "${RED}Falha ao instalar $program_name${DEFAULT}"
        return 1
    fi
}
# Definição dos programas para cada método

# Programas para instalar via APT (apenas nome do pacote)
APT_PROGRAMS=(
    "wget"              # Web Get - usado para baixar arquivos da internet diretamente pelo terminal
    "curl"              # Client URL - usado para transferir dados de/para servidores
    "git"               # Sistema de controle de versão distribuído (DVCS)
    "cmatrix"           # Simula o efeito Matrix no terminal
    "sl"                # Trem animado (ASCII art) que atravessa o terminal 
    "gnome-software-plugin-flatpak" # Suporte para a instalação e gerenciamento de aplicativos no formato Flatpak dentro do GNOME Software
    "gparted"           # GNOME Partition Editor - utilitário gráfico livre para gerenciar partições de disco
    "perl"              # Perl é uma família de duas linguagens de programação de alto nível, Perl 5 e Perl 6 (renomeada para Raku)
    "build-essential"   # Contém uma coleção de pacotes que são considerados essenciais para compilar software a partir do código-fonte
    "libspreadsheet-writeexcel-perl"    # Módulo Perl que permite criar e escrever arquivos no formato binário do Microsoft Excel (.xls)
    "libcurses-perl"    # Módulo para a linguagem Perl que fornece uma interface para a biblioteca curses (API que permite criar interfaces de texto interativas (TUI) em ambientes de terminal
    #"clamav"            # Software antivírus de código aberto utilizado para detectar e eliminar malware, como vírus e trojans
    #"plasma-discover-backend-flatpak" # Permite que o Plasma Discover liste, instale, atualize e remova aplicativos no formato Flatpak
)

# Programas para instalar via DEB (nome do programa + URL do .deb)
declare -A DEB_PROGRAMS=(
    ["google-chrome"]="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    ["balena-etcher"]="https://github.com/balena-io/etcher/releases/download/v2.1.0/balena-etcher_2.1.0_amd64.deb"
    ["textmaker24"]="https://www.freeoffice.com/download.php?filename=https://www.softmaker.net/down/softmaker-freeoffice-2024_1224-01_amd64.deb"
    ["containerd.io"]="https://download.docker.com/linux/debian/dists/bookworm/pool/stable/amd64/containerd.io_1.7.27-1_amd64.deb"
    ["docker-ce"]="https://download.docker.com/linux/debian/dists/bookworm/pool/stable/amd64/docker-ce_28.0.4-1~debian.12~bookworm_amd64.deb"
    ["docker-ce-cli"]="https://download.docker.com/linux/debian/dists/bookworm/pool/stable/amd64/docker-ce-cli_28.0.4-1~debian.12~bookworm_amd64.deb"
    ["docker-ce-rootless-extras"]="https://download.docker.com/linux/debian/dists/bookworm/pool/stable/amd64/docker-ce-rootless-extras_28.0.4-1~debian.12~bookworm_amd64.deb"
    ["docker-buildx-plugin"]="https://download.docker.com/linux/debian/dists/bookworm/pool/stable/amd64/docker-buildx-plugin_0.22.0-1~debian.12~bookworm_amd64.deb"
    ["docker-compose-plugin"]="https://download.docker.com/linux/debian/dists/bookworm/pool/stable/amd64/docker-compose-plugin_2.34.0-1~debian.12~bookworm_amd64.deb"
    ["docker-scan-plugin"]="https://download.docker.com/linux/debian/dists/bookworm/pool/stable/amd64/docker-scan-plugin_0.23.0~debian-bookworm_amd64.deb"
)

# Programas para instalar via Flatpak (nome do pacote Flatpak)
FLATPAK_PROGRAMS=(
    org.geany.Geany                 # Editor de texto leve e rápido, com recursos de um ambiente de desenvolvimento integrado (IDE) básico
    org.filezillaproject.Filezilla  # Cliente FTP (File Transfer Protocol)
    org.gimp.GIMP                   # GNU Image Manipulation Program - usado para editar imagens
    org.inkscape.Inkscape           # Usado para editar e criar gráficos vetoriais
    org.gnucash.GnuCash		    # Software de finanças pessoais gratuito, de código aberto
    org.videolan.VLC                # VLC Media Player é um reprodutor de mídia, áudio e vídeo, além de DVDs e streaming
    com.anydesk.Anydesk             # Software proprietário de desktop remoto que permite acessar e controlar um computador remotamente de outro dispositivo
    com.gitlab.davem.ClamTk         # Interface gráfica (GUI) para o ClamAV, o antivírus de código aberto
    com.visualstudio.code           # Editor de código-fonte leve, porém poderoso, desenvolvido pela Microsoft
    io.github.aandrew_me.ytdn       # Ferramenta de linha de comando ou script usado para baixar vídeos do YouTube
    cc.arduino.IDE2                 # IDE para desenvolver projetos com Arduino
    com.github.sdv43.whaler         # Fornece funcionalidade básica para o gerenciamento de contêineres Docker
)

# Programas para instalar via Snap (nome do pacote Snap)s
SNAP_PROGRAMS=(
    "htop"                  # Monitor interativo de processos para o terminal
    "neofetch-desktop"      # Exibe informações do sistema no terminal
    "disk-space-saver"
    "hollywood --classic"   # Simula uma tela de hacker hollywoodiano 
    #"asciiquarium"         # Programa de terminal que exibe uma animação de um aquário usando caracteres ASCII
    
)

# Programas com instalação personalizada (nome + comandos)
# Cada entrada é um array com o nome do programa seguido dos comandos
declare -A CUSTOM_PROGRAMS=(
    ["asciiquarium"]="sudo apt install libcurses-perl && \
    wget -P /tmp http://www.robobunny.com/projects/asciiquarium/asciiquarium.tar.gz && \
    tar -zxvf /tmp/asciiquarium.tar.gz -C /tmp/ && \
    chmod +x /tmp/asciiquarium_1.1/asciiquarium && \
    sudo cp /tmp/asciiquarium_1.1/asciiquarium /usr/local/bin/asciiquarium && \
    sudo cpan Term::Animation -y" # Qualquer problema retire o -y do comandoS
)

# Atualiza a lista de pacotes antes de começar
echo -e "${YELLOW}${BOLD}5. Instalando e atualizando programas específicos...${DEFAULT}"

# Instala programas via APT
echo -e "${YELLOW}Processando programas APT...${DEFAULT}"
for program in "${APT_PROGRAMS[@]}"; do
    echo -e "${GREEN}Verificando $program...${DEFAULT}"
    if ! is_installed "$program"; then
        install_apt "$program"
    else
        echo -e "${CYAN}$program já está instalado.${DEFAULT}"
    fi
    echo -e "${CYAN}------------------------------------------------------------${DEFAULT}"
done

# Instala programas via DEB
echo -e "${YELLOW}Processando programas DEB...${DEFAULT}"
for program in "${!DEB_PROGRAMS[@]}"; do
    echo -e "${GREEN}Verificando $program...${DEFAULT}"
    if ! is_installed "$program"; then
        install_deb "$program" "${DEB_PROGRAMS[$program]}"
    else
        echo -e "${CYAN}$program já está instalado.${DEFAULT}"
    fi
    echo -e "${CYAN}------------------------------------------------------------${DEFAULT}"
done

# Instala programas via Flatpak
echo -e "${YELLOW}Processando programas Flatpak...${DEFAULT}"
for program in "${FLATPAK_PROGRAMS[@]}"; do
    echo -e "${GREEN}Verificando $program...${DEFAULT}"
    if ! is_installed "$program"; then
        install_flatpak "$program"
    else
        echo -e "${CYAN}$program já está instalado.${DEFAULT}"
    fi
    echo -e "${CYAN}------------------------------------------------------------${DEFAULT}"
done

# Instala programas via Snap
echo -e "${YELLOW}Processando programas Snap...${DEFAULT}"
for program in "${SNAP_PROGRAMS[@]}"; do
    # Extrai o nome do programa sem opções (caso tenha --classic etc)
    program_name=$(echo "$program" | awk '{print $1}')
    echo -e "${GREEN}Verificando $program_name...${DEFAULT}"
    if ! is_installed "$program_name"; then
        install_snap "$program"
    else
        echo -e "${CYAN}$program_name já está instalado.${DEFAULT}"
    fi
    echo -e "${CYAN}------------------------------------------------------------${DEFAULT}"
done

# Instala programas com método personalizado
echo -e "${YELLOW}Processando programas com instalação personalizada...${DEFAULT}"
for program in "${!CUSTOM_PROGRAMS[@]}"; do
    echo -e "${GREEN}Verificando $program...${DEFAULT}"
    if ! is_installed "$program"; then
        install_custom "$program" "${CUSTOM_PROGRAMS[$program]}"
    else
        echo -e "${CYAN}$program já está instalado.${DEFAULT}"
    fi
    echo -e "${CYAN}------------------------------------------------------------${DEFAULT}"
done

echo -e "${CYAN}Processo de instalação concluído!${DEFAULT}"
echo ""

# 6. Remove pacotes baixados pelo APT
echo -e "${YELLOW}${BOLD}6. Removendos todos os pacotes baixados pelo APT...${DEFAULT}"
sudo apt clean -y
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao remover pacotes baixados pelo APT.${DEFAULT}"
    exit 1
else
    echo -e "${CYAN}Pacotes baixados removidos com sucesso.${DEFAULT}"
fi
echo ""

# 7. Remove pacotes que não tiveram seu download concluído
echo -e "${YELLOW}${BOLD}7. Removendo pacotes incompletos...${DEFAULT}"
sudo apt autoclean -y
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao remover pacotes incompletos.${DEFAULT}"
    exit 1
else
    echo -e "${CYAN}Pacotes incompletos removidos com sucesso.${DEFAULT}"
fi
echo ""

# 8. Remove dependências que não são mais necessárias pelo sistema
echo -e "${YELLOW}${BOLD}8. Removendo dependências que não são mais necessárias pelo sistema...${DEFAULT}"
sudo apt autoremove -y
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao remover dependências que não são mais necessárias pelo sistema.${DEFAULT}"
    exit 1
else
    echo -e "${CYAN}Dependências desnecessárias removidas com sucesso.${DEFAULT}"
fi
echo ""

# 9. Reinicia o sistema
echo -e "${YELLOW}${BOLD}9. Reiniciando o sistema em 10 segundos. Pressione Ctrl+C para cancelar.${DEFAULT}"
sleep 10
sudo reboot

#¹ O comando "&>/dev/null" redireciona a saída e os erros de um programa para o arquivo especial "/dev/null", que descarta intencionalmente qualquer dado enviado para ele.
#² A variável "$?" armazena o status de saída do último comando executado.
