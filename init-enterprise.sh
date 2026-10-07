#!/bin/bash
set -e

# Script de inicialización para Odoo Enterprise
# Este script debe ejecutarse ANTES de iniciar los contenedores por primera vez

echo "=== Inicialización de Odoo Enterprise ==="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Verificar token de GitHub
if [ -z "$GITHUB_TOKEN" ]; then
    if [ -f ".env" ]; then
        source .env
    fi
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}ERROR: No se encontró GITHUB_TOKEN${NC}"
    echo "Por favor, configura tu token en el archivo .env"
    echo "GITHUB_TOKEN=tu_token_aqui"
    exit 1
fi

# 2. Descargar módulos Enterprise
echo -e "${YELLOW}Descargando módulos Enterprise...${NC}"

if [ ! -d "enterprise/.git" ]; then
    echo "Clonando repositorio Enterprise desde La-Kolmena..."
    # Si ODOO_VERSION ya incluye .0, no agregarlo de nuevo
    if [[ "$ODOO_VERSION" == *".0" ]]; then
        BRANCH="${ODOO_VERSION:-18.0}"
    else
        BRANCH="${ODOO_VERSION:-18}.0"
    fi
    # Clonar solo la rama específica con profundidad 1
    git clone --depth 1 --branch $BRANCH https://${GITHUB_TOKEN}@github.com/La-Kolmena/enterprise2026.git enterprise

    if [ $? -ne 0 ]; then
        echo -e "${RED}Error al clonar repositorio Enterprise${NC}"
        echo -e "${RED}La rama $BRANCH no existe o no tienes acceso${NC}"
        exit 1
    fi
else
    echo "Actualizando repositorio Enterprise existente..."
    cd enterprise
    git remote set-url origin https://${GITHUB_TOKEN}@github.com/La-Kolmena/enterprise2026.git
    git pull
    cd ..
fi

# 3. Verificar que tenemos los módulos
if [ -d "enterprise" ]; then
    echo -e "${GREEN}✅ Módulos Enterprise descargados correctamente${NC}"
    MODULE_COUNT=$(find enterprise -maxdepth 1 -type d | wc -l)
    echo "   Total de módulos: $((MODULE_COUNT-1))"
else
    echo -e "${RED}⚠️  No se pudieron descargar los módulos Enterprise${NC}"
    echo "El proyecto funcionará en modo Community"
fi

# 4. Crear directorios necesarios
echo ""
echo "Creando estructura de directorios..."
mkdir -p app community
touch app/__init__.py

# 5. Verificar docker-compose.yml
echo ""
echo "Verificando configuración..."
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}ERROR: No se encontró docker-compose.yml${NC}"
    exit 1
fi

# 6. Crear red Docker si no existe
NETWORK_NAME="forge_${PROJECT_NAME}"
if ! docker network inspect $NETWORK_NAME >/dev/null 2>&1; then
    echo "Creando red Docker $NETWORK_NAME..."
    docker network create $NETWORK_NAME
fi

echo ""
echo -e "${GREEN}=== Inicialización completada ===${NC}"
echo ""
echo "Resumen:"
if [ -d "enterprise" ]; then
    MODULE_COUNT=$(find enterprise -maxdepth 1 -type d | wc -l)
    echo -e "  ${GREEN}✓${NC} Módulos Enterprise: $((MODULE_COUNT-1)) módulos disponibles"
else
    echo -e "  ${YELLOW}⚠${NC}  Módulos Enterprise: No disponibles (modo Community)"
fi
echo -e "  ${GREEN}✓${NC} Estructura de directorios creada"
echo -e "  ${GREEN}✓${NC} Red Docker configurada"
echo ""
echo "Próximos pasos:"
echo "  1. docker-compose up -d"
echo "  2. Acceder a http://localhost:${PROJECT_PORT}"
echo "  3. Configurar la base de datos"
echo ""