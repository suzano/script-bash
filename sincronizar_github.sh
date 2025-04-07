#!/bin/bash

# Diretório local onde o repositório está clonado
LOCAL_REPO="/caminho/para/seu/repositorio"

# URL do repositório no GitHub
REMOTE_REPO="https://github.com/seu-usuario/seu-repositorio.git"

# Navega até o diretório local do repositório
if [ ! -d "$LOCAL_REPO" ]; then
    echo "Diretório local não encontrado: $LOCAL_REPO"
    exit 1
fi

cd "$LOCAL_REPO"

# Verifica se o diretório é um repositório Git válido
if [ ! -d ".git" ]; then
    echo "O diretório local não é um repositório Git válido."
    exit 1
fi

# Verifica as diferenças entre o local e o remoto
echo "Verificando diferenças entre o repositório local e o remoto..."
git fetch origin

LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse origin/$(git rev-parse --abbrev-ref HEAD))

if [ "$LOCAL_HASH" == "$REMOTE_HASH" ]; then
    echo "O repositório local já está sincronizado com o remoto."
else
    echo "O repositório local está desatualizado. Atualizando..."
    git pull origin $(git rev-parse --abbrev-ref HEAD)
    if [ $? -eq 0 ]; then
        echo "Sincronização concluída com sucesso."
    else
        echo "Erro ao atualizar o repositório local."
        exit 1
    fi
fi