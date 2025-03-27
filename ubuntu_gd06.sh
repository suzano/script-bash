#!/bin/bash

################################################################################
# Script Name:  ubuntu_gd06.sh
# Description:  Faz a atualizacao do Ubuntu e limpeza dos pacotes baixados
#               ou desnecessário para o sistema.
# Author: Suzano Bitencourt
# Date: 27/03/2025
# Version: 1.0
# License: GPL-3.0
# Usage: 
#   ./ubuntu_gd06.sh
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
#   5. Remove pacotes baixados pelo APT
#   6. Remove pacotes que não tiveram seu download concluído
#   7. Remove dependências que não são mais necessárias pelo sistema
#   8. Cria usuário com permissão sudo
#   9. Verifica e instala pacotes necessários para as aulas
#   10. Adiciona PATH do LinkServer ao .bashrc do usuário
#   11. Reinicia o sistema
#
# Example:
#   sudo ./ubuntu_gd06.sh
#
# Notes:
#   - Nenhuma observacao ou erro relatado no funcionamento do script.
#
################################################################################

# 0. Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    echo "Erro: Este script deve ser executado como root."
    exit 1
fi

# 1. Verifica se existe conexao com a internet
clear
echo "1. Verificando conexão com a Internet..."
ping -c 2 google.com &> /dev/null #¹
if [ $? -eq 0 ]; then #²
    echo "Conexão com a Internet estável."
else
    echo "Sem conexão com a Internet. Verifique a rede e tente novamente."
    exit 1
fi
echo ""

# 2. Atualiza o repositorio
echo "2. Atualizando repositórios..."
sudo apt update -y
if [ $? -ne 0 ]; then
    echo "Erro ao atualizar repositórios. Verifique a configuração do apt."
    exit 1
else
    echo "Repositórios atualizados com sucesso."
fi
echo ""

# 3. Repara pacotes quebrados
echo "3. Reparando pacotes quebrados..."
sudo dpkg --configure -a
if [ $? -ne 0 ]; then
    echo "Erro ao reparar pacotes quebrados. Tente usar o comando: sudo dpkg --force-remove-reinstreq --remove <pacote>."
    exit 1
else
    echo "Pacotes quebrados reparados com sucesso."
fi
echo ""

# 4. Atualiza o sistema
echo "4. Atualizando o sistema..."
sudo apt upgrade -y
if [ $? -ne 0 ]; then
    echo "Erro ao atualizar o sistema. Verifique a configuração ou os pacotes instalados."
    exit 1
else
    echo "Sistema atualizado com sucesso."
fi
echo ""

# 5. Remove pacotes baixados pelo APT
echo "5. Removendos todos os pacotes baixados pelo APT..."
sudo apt clean -y
if [ $? -ne 0 ]; then
    echo "Erro ao remover pacotes baixados pelo APT."
    exit 1
else
    echo "Pacotes baixados removidos com sucesso."
fi
echo ""

# 6. Remove pacotes que não tiveram seu download concluído
echo "6. Removendo pacotes incompletos..."
sudo apt autoclean -y
if [ $? -ne 0 ]; then
    echo "Erro ao remover pacotes incompletos."
    exit 1
else
    echo "Pacotes incompletos removidos com sucesso."
fi
echo ""

# 7. Remove dependências que não são mais necessárias pelo sistema
echo "7. Removendo dependências que não são mais necessárias pelo sistema..."
sudo apt autoremove -y
if [ $? -ne 0 ]; then
    echo "Erro ao remover dependências que não são mais necessárias pelo sistema."
    exit 1
else
    echo "Dependências desnecessárias removidas com sucesso."
fi
echo ""

# 8. Cria usuário com permissão sudo
echo "8. Criando usuário com permissão sudo..."
if id "piloto" &>/dev/null; then
    echo "Usuário 'piloto' já existe."
else
    # Cria o usuário com as informações solicitadas
    useradd -m -c "Piloto" -s /bin/bash piloto
    echo "piloto:pilotogd06" | chpasswd
    
    # Adiciona o usuário ao grupo sudo
    usermod -aG sudo piloto
    echo "Usuário 'piloto' criado e adicionado ao grupo sudo."
fi

# 9. Verifica e instala pacotes necessários para as aulas
echo "Verificando e instalando pacotes necessários..."

# Lista de pacotes a serem instalados
packages=(
    git
    cmake
    ninja-build
    gperf
    ccache
    dfu-util
    device-tree-compiler
    wget
    python3-dev
    python3-pip
    python3-setuptools
    python3-tk
    python3-wheel
    xz-utils file
    make
    gcc
    gcc-multilib
    g++-multilib
    libsdl2-dev
    libmagic1
    python3-venv
)

# Verifica e instala cada pacote
for pkg in "${packages[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg "; then
        echo "$pkg já está instalado."
    else
        echo "Instalando $pkg..."
        apt-get install --no-install-recommends -y "$pkg"
    fi
done

# 10. Adiciona PATH do LinkServer ao .bashrc do usuário
echo "Configurando .bashrc do usuário piloto..."

bashrc_line="export PATH=\$PATH:/usr/local/LinkServer"

# Verifica se a linha já existe no .bashrc
if [ -f /home/piloto/.bashrc ] && grep -q "$bashrc_line" /home/piloto/.bashrc; then
    echo "A linha já existe no .bashrc do usuário piloto."
else
    echo "$bashrc_line" >> /home/piloto/.bashrc
    echo "Linha adicionada ao .bashrc do usuário piloto."
    
    # Ajusta as permissões do arquivo .bashrc
    chown piloto:piloto /home/piloto/.bashrc
fi

echo "Configuração concluída com sucesso!"


# 8. Reinicia o sistema
echo "8. Reiniciando o sistema em 10 segundos. Pressione Ctrl+C para cancelar."
sleep 10
sudo reboot

#¹ O comando "&>/dev/null" redireciona a saída e os erros de um programa para o arquivo especial "/dev/null", que descarta intencionalmente qualquer dado enviado para ele.
#² A variável "$?" armazena o status de saída do último comando executado.