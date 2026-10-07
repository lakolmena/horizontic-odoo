#!/bin/bash

# Carpeta del logfile (odoo.conf: logfile=/var/log/odoo/odoo.log) — sin ella, Odoo no puede escribir su log
mkdir -p /var/log/odoo && chown odoo /var/log/odoo 2>/dev/null || true
set -e

echo "=== Iniciando Odoo Enterprise Edition ==="
echo "Variables de entorno:"
echo "HOST=$HOST"
echo "USER=$USER"
echo "POSTGRES_DB=$POSTGRES_DB"
echo "ODOO_VERSION=${ODOO_VERSION:-18}"
echo "GITHUB_TOKEN configurado: $([ -n "$GITHUB_TOKEN" ] && echo 'Sí' || echo 'No')"

# PASO 1: Descargar módulos Enterprise si no existen
if [ ! -d "/mnt/enterprise-addons" ] || [ -z "$(ls -A /mnt/enterprise-addons 2>/dev/null)" ]; then
    echo ""
    echo "=== Descargando módulos Enterprise ==="
    
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "⚠️  ERROR: No se encontró GITHUB_TOKEN"
        echo "Los módulos Enterprise no se pueden descargar sin token"
        echo "El sistema funcionará en modo Community"
    else
        # Crear directorio temporal para clonar
        TEMP_DIR="/tmp/enterprise-clone"
        rm -rf $TEMP_DIR
        
        echo "Clonando repositorio Enterprise..."
        # Si ODOO_VERSION ya incluye .0, no agregarlo de nuevo
        if [[ "$ODOO_VERSION" == *".0" ]]; then
            BRANCH="${ODOO_VERSION:-18.0}"
        else
            BRANCH="${ODOO_VERSION:-18}.0"
        fi
        # Clonar solo la rama específica con profundidad 1 para ahorrar espacio y tiempo
        git clone --depth 1 --branch $BRANCH https://${GITHUB_TOKEN}@github.com/La-Kolmena/enterprise2026.git $TEMP_DIR

        if [ $? -eq 0 ]; then
            cd $TEMP_DIR
            echo "✅ Clonado exitosamente rama $BRANCH"
            
            # Copiar módulos al volumen montado
            echo "Copiando módulos al directorio de addons..."
            cp -r * /mnt/enterprise-addons/ 2>/dev/null || true
            cd /
            rm -rf $TEMP_DIR
            
            echo "✅ Módulos Enterprise descargados correctamente"
            MODULE_COUNT=$(find /mnt/enterprise-addons -maxdepth 1 -type d | wc -l)
            echo "   Total de módulos: $((MODULE_COUNT-1))"
        else
            echo "⚠️  Error al clonar repositorio Enterprise"
        fi
    fi
else
    echo "✅ Módulos Enterprise ya disponibles"
    MODULE_COUNT=$(find /mnt/enterprise-addons -maxdepth 1 -type d | wc -l)
    echo "   Total de módulos: $((MODULE_COUNT-1))"
fi

# PASO 2: Esperar a que PostgreSQL esté listo
echo ""
echo "=== Esperando a PostgreSQL ==="
for i in {1..30}; do
    if PGPASSWORD=$PASSWORD psql -h "$HOST" -U "$USER" -d "postgres" -c '\q' 2>/dev/null; then
        echo "✅ PostgreSQL está listo"
        break
    fi
    echo "   Esperando... intento $i/30"
    sleep 2
done

# PASO 3: Verificar si la base de datos necesita inicialización
echo ""
echo "=== Verificando base de datos ==="
NEEDS_INIT=false
if ! PGPASSWORD=$PASSWORD psql -h "$HOST" -U "$USER" -d "$POSTGRES_DB" -c "SELECT 1 FROM ir_module_module LIMIT 1" 2>/dev/null; then
    echo "   Base de datos no inicializada"
    NEEDS_INIT=true
else
    echo "✅ Base de datos ya inicializada"
fi

# PASO 4: Construir el addons_path dinámicamente
ADDONS_PATH=""
if [ -d "/mnt/enterprise-addons" ] && [ -n "$(ls -A /mnt/enterprise-addons 2>/dev/null)" ]; then
    ADDONS_PATH="/mnt/enterprise-addons"
    echo "✅ Path Enterprise configurado"
fi

# Módulos propios primero, para que puedan sobrescribir al resto
if ls /mnt/custom-addons/*/__manifest__.py >/dev/null 2>&1; then
    ADDONS_PATH="/mnt/custom-addons${ADDONS_PATH:+,$ADDONS_PATH}"
fi

# Repos OCA clonados en community/ (cada repo es un directorio de addons)
if [ -d "/mnt/community-addons" ]; then
    for repo in /mnt/community-addons/*/; do
        repo="${repo%/}"
        if ls "$repo"/*/__manifest__.py >/dev/null 2>&1; then
            ADDONS_PATH="${ADDONS_PATH:+$ADDONS_PATH,}$repo"
        fi
    done
    # Módulos sueltos directamente en community/
    if ls /mnt/community-addons/*/__manifest__.py >/dev/null 2>&1; then
        ADDONS_PATH="${ADDONS_PATH:+$ADDONS_PATH,}/mnt/community-addons"
    fi
fi

if [ -d "/mnt/extra-addons" ]; then
    if find /mnt/extra-addons -mindepth 1 -maxdepth 1 -type d | grep -q .; then
        if [ -n "$ADDONS_PATH" ]; then
            ADDONS_PATH="$ADDONS_PATH,/mnt/extra-addons"
        else
            ADDONS_PATH="/mnt/extra-addons"
        fi
    fi
fi

# Siempre añadir el path por defecto al final
if [ -n "$ADDONS_PATH" ]; then
    ADDONS_PATH="$ADDONS_PATH,/usr/lib/python3/dist-packages/odoo/addons"
else
    ADDONS_PATH="/usr/lib/python3/dist-packages/odoo/addons"
fi

echo ""
echo "=== Configuración final ==="
echo "Addons path: $ADDONS_PATH"

# PASO 5: Inicializar o ejecutar Odoo
if [ "$NEEDS_INIT" = "true" ]; then
    echo ""
    echo "=== Inicializando base de datos con Enterprise ==="
    echo "Instalando módulos base + web_enterprise..."
    
    # Inicializar con base y web_enterprise de una vez con idioma seleccionado
    USER_LANG="${ODOO_LANG:-es_ES.UTF-8}"
    LANG_CODE=$(echo "$USER_LANG" | cut -d'.' -f1)  # Convertir es_ES.UTF-8 a es_ES
    echo "Inicializando con idioma: $USER_LANG (código: $LANG_CODE)"
    
    # Instalar módulos base y web_enterprise con idioma seleccionado
    odoo --db_host="$HOST" --db_port=5432 --db_user="$USER" --db_password="$PASSWORD" \
        --addons-path="$ADDONS_PATH" \
        -d "$POSTGRES_DB" \
        -i base,web_enterprise \
        --without-demo="$WITHOUT_DEMO" \
        --load-language="$LANG_CODE" \
        --stop-after-init
    
    # Instalar paquete de localización según el idioma
    if [ "$LANG_CODE" = "es_ES" ] || [ "$LANG_CODE" = "es" ]; then
        echo "Instalando localización española..."
        odoo --db_host="$HOST" --db_port=5432 --db_user="$USER" --db_password="$PASSWORD" \
            --addons-path="$ADDONS_PATH" \
            -d "$POSTGRES_DB" \
            -i l10n_es \
            --stop-after-init
    elif [ "$LANG_CODE" = "en_US" ] || [ "$LANG_CODE" = "en" ]; then
        echo "Usando localización inglesa por defecto"
    fi
    
    # Configurar credenciales del admin y actualizar idioma
    echo "Configurando credenciales del administrador..."
    ADMIN_USER="${ODOO_ADMIN_USER:-admin}"
    ADMIN_PASS="${ADMIN_PASSWORD:-admin}"
    
    # Verificar si la columna lang existe antes de actualizar
    if PGPASSWORD="$PASSWORD" psql -h "$HOST" -U "$USER" -d "$POSTGRES_DB" -c "\d res_users" | grep -q " lang "; then
        echo "Configurando idioma por defecto para usuarios: $LANG_CODE"
        
        # Actualizar usuario admin con credenciales e idioma
        if [ "$ADMIN_USER" != "admin" ]; then
            echo "Creando usuario personalizado: $ADMIN_USER"
            PGPASSWORD="$PASSWORD" psql -h "$HOST" -U "$USER" -d "$POSTGRES_DB" \
                -c "UPDATE res_users SET login='$ADMIN_USER', password='$ADMIN_PASS', lang='$LANG_CODE' WHERE login='admin';"
        else
            echo "Actualizando contraseña y idioma del usuario admin por defecto"
            PGPASSWORD="$PASSWORD" psql -h "$HOST" -U "$USER" -d "$POSTGRES_DB" \
                -c "UPDATE res_users SET password='$ADMIN_PASS', lang='$LANG_CODE' WHERE login='admin';"
        fi
        
        # Configurar idioma por defecto para la compañía y usuarios nuevos
        echo "Configurando idioma por defecto para la compañía"
        PGPASSWORD="$PASSWORD" psql -h "$HOST" -U "$USER" -d "$POSTGRES_DB" \
            -c "UPDATE res_partner SET lang='$LANG_CODE' WHERE id IN (SELECT partner_id FROM res_company);"
        
        # También actualizar cualquier compañía que tenga nombres comunes
        PGPASSWORD="$PASSWORD" psql -h "$HOST" -U "$USER" -d "$POSTGRES_DB" \
            -c "UPDATE res_partner SET lang='$LANG_CODE' WHERE name IN ('YourCompany', 'My Company', 'Empresa');"
    else
        echo "Columna lang no disponible, solo actualizando credenciales"
        # Solo actualizar credenciales
        if [ "$ADMIN_USER" != "admin" ]; then
            PGPASSWORD="$PASSWORD" psql -h "$HOST" -U "$USER" -d "$POSTGRES_DB" \
                -c "UPDATE res_users SET login='$ADMIN_USER', password='$ADMIN_PASS' WHERE login='admin';"
        else
            PGPASSWORD="$PASSWORD" psql -h "$HOST" -U "$USER" -d "$POSTGRES_DB" \
                -c "UPDATE res_users SET password='$ADMIN_PASS' WHERE login='admin';"
        fi
    fi
    
    echo "✅ Base de datos inicializada con Enterprise"
fi

# PASO 6: Ejecutar Odoo normalmente
echo ""
echo "=== Iniciando Odoo Enterprise ==="
echo "URL: http://localhost:8069"
echo "Usuario: ${ODOO_ADMIN_USER:-admin}"
echo ""

exec odoo --db_host="$HOST" --db_port=5432 --db_user="$USER" --db_password="$PASSWORD" \
    --addons-path="$ADDONS_PATH" \
    --proxy-mode \
    --without-demo="$WITHOUT_DEMO"