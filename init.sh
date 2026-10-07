#!/bin/bash
# Script de inicialización para Odoo Enterprise

set -e

echo "=== Inicializando proyecto Odoo Enterprise ==="

# Crear directorios necesarios
mkdir -p app enterprise community

# Crear archivo .gitignore específico para Odoo
cat > .gitignore << 'EOF'
# Odoo
*.pyc
__pycache__/
.DS_Store
*.log
*.pot
*.mo

# Enterprise repository (si se clona)
enterprise/

# Virtual environments
venv/
env/

# IDEs
.vscode/
.idea/
*.swp
*.swo

# Docker
*.pid

# Backups
*.dump
*.sql
backups/
EOF

# Instrucciones para el usuario
echo ""
echo "✅ Proyecto Odoo Enterprise inicializado"
echo ""
echo "📋 Próximos pasos:"
echo ""
echo "1. Clonar el repositorio Enterprise (requiere acceso):"
echo "   git clone https://github.com/odoo/enterprise.git ./enterprise"
echo ""
echo "2. (Opcional) Añadir módulos Community adicionales:"
echo "   git clone https://github.com/OCA/server-tools.git ./community/server-tools"
echo ""
echo "3. Iniciar el proyecto:"
echo "   docker-compose up -d"
echo ""
echo "4. Acceder a Odoo:"
echo "   http://localhost:${PROJECT_PORT}"
echo ""
echo "⚠️  Nota: Si no tienes acceso a Enterprise, el sistema funcionará como Community Edition"