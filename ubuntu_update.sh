#!/bin/bash

################################################################################
# Script Name:  ubuntu_update.sh
# Description:  Faz a atualizacao do Ubuntu e limpeza dos pacotes baixados
#               ou desnecessário para o sistema.
# Author: Suzano Bitencourt
# Date: 20/11/2024
# Version: 1.0
# License: GPL-3.0
# Usage: 
#   ./ubuntu_update.sh
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
#
################################################################################

# Definição de códigos de cores ANSI
H1='\033[1;34m'                 # Títulos (Azul)
H2='\033[0;36m'                 # Subtítulos (Ciano)
DEFAULT='\033[0m'               # Reset para a cor padrão

# Ícones simples
SUCCESS='\033[0;32m[\u2714]'    # Sucesso (Verde) SIMPLES
ERROR='\033[0;31m[\u2718]'      # Erro (Vermelho) SIMPLES
WARNING='\033[0;33m[\u2691]'    # Aviso (Amarelo) SIMPLES

# Ícones coloridos
#SUCCESS='\033[0;32m\u2705'    # Sucesso (Verde) COLORIDO
#ERROR='\033[0;31m\u26D4'      # Erro (Vermelho) COLORIDO
#WARNING='\033[0;33m\u23F3'    # Aviso (Amarelo) COLORIDO

# Ícones quadrados
#SUCCESS='\033[0;32m\u2611'    # Sucesso (Verde) QUADRADO
#ERROR='\033[0;31m\u2612'      # Erro (Vermelho) QUADRADO
#WARNING='\033[0;33m\u2610'    # Aviso (Amarelo) QUADRADO

# 0. Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    echo -e "${ERROR}Este script deve ser executado como root.${DEFAULT}"
    exit 1
fi

# 1. Verifica se existe conexao com a internet
clear
echo -e "${H1}1. Verificando conexão com a Internet...${DEFAULT}"
ping -c 2 google.com &> /dev/null #¹
if [ $? -eq 0 ]; then #²
    echo -e "${SUCCESS}Conexão com a Internet estável.${DEFAULT}"
else
    echo -e "${ERROR}Sem conexão com a Internet. Verifique a rede e tente novamente.${DEFAULT}"
    exit 1
fi
echo ""

# 2. Atualiza o repositório
echo -e "${H1}2. Atualizando repositórios...${DEFAULT}"
sudo apt update -y
if [ $? -ne 0 ]; then
    echo -e "${ERROR}Erro ao atualizar repositórios. Verifique a configuração do apt.${DEFAULT}"
    exit 1
else
    echo -e "${SUCCESS}Repositórios atualizados com sucesso.${DEFAULT}"
fi
echo ""

# 3. Repara pacotes quebrados
echo -e "${H1}3. Reparando pacotes quebrados...${DEFAULT}"
sudo dpkg --configure -a
sudo apt --fix-broken install
if [ $? -ne 0 ]; then
    echo -e "${ERROR}Erro ao reparar pacotes quebrados. Tente usar o comando: sudo dpkg --force-remove-reinstreq --remove <pacote>.${DEFAULT}"
    exit 1
else
    echo -e "${SUCCESS}Pacotes quebrados reparados com sucesso.${DEFAULT}"
fi
echo ""

# 4. Atualiza o sistema
echo -e "${H1}4. Atualizando o sistema...${DEFAULT}"
sudo apt upgrade -y
# sudo apt dist-upgrade -y
if [ $? -ne 0 ]; then
    echo -e "${ERROR}Erro ao atualizar o sistema. Verifique a configuração ou os pacotes instalados.${DEFAULT}"
    exit 1
else
    echo -e "${SUCCESS}Sistema atualizado com sucesso.${DEFAULT}"
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
    echo -e "${WARNING}Instalando $program_name via APT...${DEFAULT}"
    sudo apt install -y "$program_name"
}

# Função para instalar um programa via arquivo .deb
function install_deb() {
    local program_name=$1
    local download_url=$2
    local temp_dir=$(mktemp -d)
    
    echo -e "${WARNING}Instalando $program_name via DEB...${DEFAULT}"
    echo -e "${WARNING}Baixando pacote de $download_url${DEFAULT}"
    
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

# Função para instalar um programa via Flatpak
function install_flatpak() {
    local program_name=$1
    echo -e "${WARNING}Instalando $program_name via Flatpak...${DEFAULT}"
    
    # Verifica se o Flatpak está instalado
    if ! command -v flatpak &>/dev/null; then
        echo -e "${WARNING}Flatpak não está instalado. Instalando...${DEFAULT}"
        sudo apt install -y flatpak
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        echo -e "${WARNING}Flatpak foi instalando com sucesso. Para funcionar corretamente, o sistema precisa ser reiniciado...${DEFAULT}"
        sleep 10
        sudo reboot
    fi
    
    flatpak install flathub "$program_name" -y
}

# Função para instalar um programa via Snap
function install_snap() {
    local program_name=$1
    echo -e "${WARNING}Instalando $program_name via Snap...${DEFAULT}"
    
    # Verifica se o Snap está instalado
    if ! command -v snap &>/dev/null; then
        echo -e "${WARNING}Snap não está instalado. Instalando...${DEFAULT}"
        sudo apt install -y snapd
    fi
    
    sudo snap install "$program_name"
}

# Função para instalação personalizada
function install_custom() {
    local program_name=$1
    local install_script=$2
        
    echo -e "${WARNING}Instalando $program_name via comandos personalizados...${DEFAULT}"
    echo -e "${WARNING}Executando os seguintes comandos:${DEFAULT}"
        
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
# Definição dos programas para cada método

# Programas para instalar via APT (apenas nome do pacote)
APT_PROGRAMS=(
    "wget"              # Web Get - usado para baixar arquivos da internet diretamente pelo terminal
    "curl"              # Client URL - usado para transferir dados de/para servidores
    "git-all"               # Sistema de controle de versão distribuído (DVCS)
    "cmatrix"           # Simula o efeito Matrix no terminal
    "sl"                # Trem animado (ASCII art) que atravessa o terminal 
    "gnome-software-plugin-flatpak" # Suporte para a instalação e gerenciamento de aplicativos no formato Flatpak dentro do GNOME Software
    "gparted"           # GNOME Partition Editor - utilitário gráfico livre para gerenciar partições de disco
    "perl"              # Perl é uma família de duas linguagens de programação de alto nível, Perl 5 e Perl 6 (renomeada para Raku)
    "build-essential"   # Contém uma coleção de pacotes que são considerados essenciais para compilar software a partir do código-fonte
    "libspreadsheet-writeexcel-perl"    # Módulo Perl que permite criar e escrever arquivos no formato binário do Microsoft Excel (.xls)
    "libcurses-perl"    # Módulo para a linguagem Perl que fornece uma interface para a biblioteca curses (API que permite criar interfaces de texto interativas (TUI) em ambientes de terminal
    "htop"                  # Monitor interativo de processos para o terminal
    "neofetch"      # Exibe informações do sistema no terminal
    #"clamav"            # Software antivírus de código aberto utilizado para detectar e eliminar malware, como vírus e trojans
    #"plasma-discover-backend-flatpak" # Permite que o Plasma Discover liste, instale, atualize e remova aplicativos no formato Flatpak
)

# Programas para instalar via DEB (nome do programa + URL do .deb)
declare -A DEB_PROGRAMS=(
    ["google-chrome"]="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    ["balena-etcher"]="https://github.com/balena-io/etcher/releases/download/v2.1.0/balena-etcher_2.1.0_amd64.deb"
    ["textmaker24"]="https://www.freeoffice.com/download.php?filename=https://www.softmaker.net/down/softmaker-freeoffice-2024_1224-01_amd64.deb"
)

# Programas para instalar via Flatpak (nome do pacote Flatpak)
FLATPAK_PROGRAMS=(
    org.geany.Geany                 # Editor de texto leve e rápido, com recursos de um ambiente de desenvolvimento integrado (IDE) básico
    org.filezillaproject.Filezilla  # Cliente FTP (File Transfer Protocol)
    org.gimp.GIMP                   # GNU Image Manipulation Program - usado para editar imagens
    org.inkscape.Inkscape           # Usado para editar e criar gráficos vetoriais
    org.gnucash.GnuCash		    	# Software de finanças pessoais gratuito, de código aberto
    org.videolan.VLC                # VLC Media Player é um reprodutor de mídia, áudio e vídeo, além de DVDs e streaming
    com.anydesk.Anydesk             # Software proprietário de desktop remoto que permite acessar e controlar um computador remotamente de outro dispositivo
    com.gitlab.davem.ClamTk         # Interface gráfica (GUI) para o ClamAV, o antivírus de código aberto
    com.visualstudio.code           # Editor de código-fonte leve, porém poderoso, desenvolvido pela Microsoft
    io.github.aandrew_me.ytdn       # Ferramenta de linha de comando ou script usado para baixar vídeos do YouTube
    cc.arduino.IDE2                 # IDE para desenvolver projetos com Arduino
)

# Programas para instalar via Snap (nome do pacote Snap)s
SNAP_PROGRAMS=(
    "disk-space-saver"
    "hollywood --classic"   # Simula uma tela de hacker hollywoodiano 
    "asciiquarium"         # Programa de terminal que exibe uma animação de um aquário usando caracteres ASCII 
)

# Programas com instalação personalizada (nome + comandos)
# Cada entrada é um array com o nome do programa seguido dos comandos
declare -A CUSTOM_PROGRAMS=(
    # Asciiquarium - programa de terminal que exibe uma animação de um aquário usando caracteres ASCII
    #["asciiquarium"]="sudo apt install libcurses-perl && \
    #wget -P /tmp http://www.robobunny.com/projects/asciiquarium/asciiquarium.tar.gz && \
    #tar -zxvf /tmp/asciiquarium.tar.gz -C /tmp/ && \
    #chmod +x /tmp/asciiquarium_1.1/asciiquarium && \
    #sudo cp /tmp/asciiquarium_1.1/asciiquarium /usr/local/bin/asciiquarium && \
    #sudo cpan Term::Animation -y" # Qualquer problema retire o -y do comando

    # Docker-CE para Debian 12
    #["docker-ce"]="sudo apt install -y ca-certificates curl && \
    #sudo install -m 0755 -d /etc/apt/keyrings && \
    #sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    #sudo chmod a+r /etc/apt/keyrings/docker.asc && \
    #echo  \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    #sudo apt-get update -y && \
    #sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose docker-compose-plugin"
    
    # Docker-CE para Ubuntu 24.04
    #["docker-ce"]="sudo apt-get install -y ca-certificates curl && \
    #sudo install -m 0755 -d /etc/apt/keyrings && \
    #sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    #sudo chmod a+r /etc/apt/keyrings/docker.asc && \
    #echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"${UBUNTU_CODENAME:-$VERSION_CODENAME}\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    #sudo apt-get update -y && \
    #sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose docker-compose-plugin"
   
    # Portainer-CE - ferramenta de gerenciamento de contêineres de código aberto e leve, que oferece uma interface web intuitiva para administrar ambientes Docker, Docker Swarm, Kubernetes e Nomad
    #["portainer"]="
    #if docker ps -a --format '{{.Names}}' | grep -q 'portainer'; then  && \
    #echo \"Portainer está instalado como container Docker.\" && \
#		if docker ps --format '{{.Names}}' | grep -q 'portainer'; then && \
#			echo -e \"\nO Portainer está atualmente rodando.\" && \
#		else && \
#			echo -e \"\nO Portainer não está rodando no momento.\" && \
#		fi && \
#	else && \
#		echo -e \"\nO Portainer não está instalado.\" && \
#	fi && \
#		
#		docker volume create portainer_data
#		docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:lts
#	fi

# Verifica se o Portainer CE está instalado via pacote (para sistemas que usam apt)
#if command -v apt &>/dev/null; then
#    if dpkg -l | grep -q 'portainer-ce'; then
#        echo -e "\nPortainer CE está instalado via pacote apt."
#    else
#        echo -e "\nPortainer CE não está instalado via pacote apt."
#    fi
#fi
#       docker volume create portainer_data
#    docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:lts
#   " # Acesse: https://localhost:9443 Obs.: Por padrão, o Portainer gera e usa um certificado SSL auto-assinado para proteger a porta 9443. Se você precisar de porta HTTP por #motivos legados, altere para a porta 9000.
#
)
# Atualiza a lista de pacotes antes de começar
echo -e "${H1}5. Instalando e atualizando programas específicos...${DEFAULT}"

# Instala programas via APT
echo -e "${H2}Processando programas APT...${DEFAULT}"
for program in "${APT_PROGRAMS[@]}"; do
    echo -e "${WARNING}Verificando $program...${DEFAULT}"
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
    echo -e "${WARNING}Verificando $program...${DEFAULT}"
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
    echo -e "${WARNING}Verificando $program...${DEFAULT}"
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
    echo -e "${WARNING}Verificando $program_name...${DEFAULT}"
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
    echo -e "${WARNING}Verificando $program...${DEFAULT}"
    if ! is_installed "$program"; then
        install_custom "$program" "${CUSTOM_PROGRAMS[$program]}"
    else
        echo -e "${SUCCESS}$program já está instalado.${DEFAULT}"
    fi
    echo -e "------------------------------------------------------------"
done

echo -e "${SUCCESS}Processo de instalação concluído!${DEFAULT}"
echo ""

# 6. Remove pacotes baixados pelo APT
echo -e "${H1}6. Removendos todos os pacotes baixados pelo APT...${DEFAULT}"
sudo apt clean -y
if [ $? -ne 0 ]; then
    echo -e "${ERROR}Erro ao remover pacotes baixados pelo APT.${DEFAULT}"
    exit 1
else
    echo -e "${SUCCESS}Pacotes baixados removidos com sucesso.${DEFAULT}"
fi
echo ""

# 7. Remove pacotes que não tiveram seu download concluído
echo -e "${H1}7. Removendo pacotes incompletos...${DEFAULT}"
sudo apt autoclean -y
if [ $? -ne 0 ]; then
    echo -e "${ERROR}Erro ao remover pacotes incompletos.${DEFAULT}"
    exit 1
else
    echo -e "${SUCCESS}Pacotes incompletos removidos com sucesso.${DEFAULT}"
fi
echo ""

# 8. Remove dependências que não são mais necessárias pelo sistema
echo -e "${H1}8. Removendo dependências que não são mais necessárias pelo sistema...${DEFAULT}"
sudo apt autoremove -y
if [ $? -ne 0 ]; then
    echo -e "${ERROR}Erro ao remover dependências que não são mais necessárias pelo sistema.${DEFAULT}"
    exit 1
else
    echo -e "${SUCCESS}Dependências desnecessárias removidas com sucesso.${DEFAULT}"
fi
echo ""

# 9. Reinicia o sistema
echo -e "${H1}9. Reiniciando o sistema em 10 segundos. Pressione Ctrl+C para cancelar.${DEFAULT}"
#sleep 10
#sudo reboot

#¹ O comando "&>/dev/null" redireciona a saída e os erros de um programa para o arquivo especial "/dev/null", que descarta intencionalmente qualquer dado enviado para ele.
#² A variável "$?" armazena o status de saída do último comando executado.
