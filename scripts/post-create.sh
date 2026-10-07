#!/bin/bash
# Script que se ejecuta automáticamente después de crear el proyecto
# para descargar los módulos Enterprise antes de iniciar Odoo

set -e

echo "=== Post-create script para Odoo Enterprise ==="

# Cargar variables de entorno
if [ -f ".env" ]; then
    source .env
fi

# Ejecutar el script de inicialización de Enterprise
if [ -f "init-enterprise.sh" ]; then
    echo "Ejecutando inicialización de módulos Enterprise..."
    chmod +x init-enterprise.sh
    ./init-enterprise.sh
    
    if [ $? -eq 0 ]; then
        echo "✅ Módulos Enterprise descargados correctamente"
    else
        echo "⚠️ Error al descargar módulos Enterprise"
        exit 1
    fi
else
    echo "⚠️ No se encontró init-enterprise.sh"
fi

# Hacer odoo.conf escribible por el usuario odoo del contenedor (uid 100).
# El contenedor corre Odoo como 'odoo', pero el odoo.conf se crea como 'ubuntu' (644),
# así que Odoo no puede escribirlo: al fijar la master password desde la interfaz falla
# en silencio (IOError) y no persiste. Con permiso de escritura, se guarda correctamente.
if [ -f "odoo.conf" ]; then
    chmod 666 odoo.conf
    echo "✅ odoo.conf con permisos de escritura (la master password persistirá)"
fi

echo "=== Post-create completado ==="

# Carpeta de logs del host (montada como /var/log/odoo en el contenedor)
mkdir -p logs && chmod 777 logs
