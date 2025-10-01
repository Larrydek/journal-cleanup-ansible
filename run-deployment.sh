#!/bin/bash

set -e

echo "=== Despliegue Limpieza Journal PLC ==="

# Verificar Ansible
if ! command -v ansible-playbook &> /dev/null; then
    echo "Error: Ansible no está instalado"
    echo "Instalar con: sudo apt install ansible sshpass"
    exit 1
fi

# Verificar archivos necesarios
files_to_check=(
    "files/vacuum-journal.service"
    "files/vacuum-journal.timer"
    "inventory.yml"
    "deploy.yml"
)

for file in "${files_to_check[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "Error: Archivo no encontrado: $file"
        exit 1
    fi
done

echo "✓ Archivos verificados"
echo "Iniciando despliegue de limpieza journal..."

# Ejecutar playbook
ansible-playbook deploy.yml -v

echo "✓ Despliegue completado - Limpieza journal configurada"