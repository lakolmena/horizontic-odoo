#!/bin/bash
set -e

echo "Iniciando Odoo Enterprise Edition..."
echo "Variables de entorno:"
echo "HOST=$HOST"
echo "USER=$USER"
echo "POSTGRES_DB=$POSTGRES_DB"
echo "ODOO_VERSION=${ODOO_VERSION:-18}"

# Verificar si existen los módulos Enterprise
if [ ! -d "/mnt/enterprise-addons" ] || [ -z "$(ls -A /mnt/enterprise-addons 2>/dev/null)" ]; then
    echo "⚠️  ADVERTENCIA: No se encontraron módulos Enterprise en /mnt/enterprise-addons"
    echo "Para activar Enterprise, clone el repositorio en ./enterprise/"
    echo "Ejemplo: git clone https://github.com/odoo/enterprise.git ./enterprise"
fi

# Esperar a que PostgreSQL esté listo
echo "Esperando a que PostgreSQL esté listo..."
for i in {1..30}; do
    if PGPASSWORD=$PASSWORD psql -h "$HOST" -U "$USER" -d "postgres" -c '\q' 2>/dev/null; then
        echo "PostgreSQL está listo"
        break
    fi
    echo "Esperando... intento $i/30"
    sleep 2
done

# Verificar si la base de datos necesita inicialización
echo "Verificando estado de la base de datos..."
NEEDS_INIT=false
if ! PGPASSWORD=$PASSWORD psql -h "$HOST" -U "$USER" -d "$POSTGRES_DB" -c "SELECT 1 FROM ir_module_module LIMIT 1" 2>/dev/null; then
    echo "Base de datos no inicializada, se instalará el módulo base"
    NEEDS_INIT=true
fi

# Construir el addons_path dinámicamente
ADDONS_PATH=""
if [ -d "/mnt/enterprise-addons" ] && [ -n "$(ls -A /mnt/enterprise-addons 2>/dev/null)" ]; then
    ADDONS_PATH="/mnt/enterprise-addons"
    echo "✅ Módulos Enterprise detectados y añadidos al path"
fi
if [ -d "/mnt/community-addons" ] && [ -n "$(ls -A /mnt/community-addons 2>/dev/null)" ]; then
    if [ -n "$ADDONS_PATH" ]; then
        ADDONS_PATH="$ADDONS_PATH,/mnt/community-addons"
    else
        ADDONS_PATH="/mnt/community-addons"
    fi
fi
# Solo añadir extra-addons si existe y tiene contenido
if [ -d "/mnt/extra-addons" ] && [ -n "$(ls -A /mnt/extra-addons 2>/dev/null)" ]; then
    # Crear un archivo __init__.py vacío si no existe
    touch /mnt/extra-addons/__init__.py 2>/dev/null || true
    if [ -n "$ADDONS_PATH" ]; then
        ADDONS_PATH="$ADDONS_PATH,/mnt/extra-addons"
    else  
        ADDONS_PATH="/mnt/extra-addons"
    fi
fi
# Siempre añadir el path por defecto al final
if [ -n "$ADDONS_PATH" ]; then
    ADDONS_PATH="$ADDONS_PATH,/usr/lib/python3/dist-packages/odoo/addons"
else
    ADDONS_PATH="/usr/lib/python3/dist-packages/odoo/addons"
fi

echo "Addons path configurado: $ADDONS_PATH"

# Ejecutar Odoo con o sin inicialización
if [ "$NEEDS_INIT" = "true" ]; then
    echo "Inicializando base de datos con módulo base..."
    echo "Contraseña admin configurada: ${ADMIN_PASSWORD:-admin}"
    
    # Primero inicializar la base de datos
    odoo --db_host="$HOST" --db_port=5432 --db_user="$USER" --db_password="$PASSWORD" \
        --addons-path="$ADDONS_PATH" \
        -d "$POSTGRES_DB" \
        -i base \
        --without-demo="$WITHOUT_DEMO" \
        --stop-after-init
    
    # Luego configurar las credenciales del admin directamente en la BD
    echo "Configurando credenciales del administrador..."
    ADMIN_USER="${ODOO_ADMIN_USER:-admin}"
    ADMIN_PASS="${ADMIN_PASSWORD:-admin}"
    
    echo "Usuario admin: $ADMIN_USER"
    echo "Contraseña configurada: $ADMIN_PASS"
    
    # Si el usuario no es 'admin', crear el nuevo usuario y eliminar el por defecto
    if [ "$ADMIN_USER" != "admin" ]; then
        echo "Creando usuario personalizado: $ADMIN_USER"
        PGPASSWORD="$PASSWORD" psql -h "$HOST" -U "$USER" -d "$POSTGRES_DB" \
            -c "UPDATE res_users SET login='$ADMIN_USER', password='$ADMIN_PASS' WHERE login='admin';"
    else
        echo "Actualizando contraseña del usuario admin por defecto"
        PGPASSWORD="$PASSWORD" psql -h "$HOST" -U "$USER" -d "$POSTGRES_DB" \
            -c "UPDATE res_users SET password='$ADMIN_PASS' WHERE login='admin';"
    fi
    
    echo "Iniciando Odoo después de la inicialización..."
fi

# Iniciar Odoo normalmente
echo "Iniciando Odoo..."
exec odoo --db_host="$HOST" --db_port=5432 --db_user="$USER" --db_password="$PASSWORD" \
    --addons-path="$ADDONS_PATH" \
    -d "$POSTGRES_DB"