# Odoo Enterprise Template para FORGE

Esta plantilla despliega Odoo Enterprise Edition con Docker, descargando automáticamente los módulos Enterprise.

## Características Principales

- **Descarga automática de módulos Enterprise** al iniciar por primera vez
- **Interfaz Enterprise** activada desde el inicio (web_enterprise)
- **661+ módulos Enterprise** disponibles
- **PostgreSQL dedicado** para cada proyecto
- **Multi-versión**: Soporta Odoo 14, 15, 16, 17 y 18

## Requisitos

- Token de GitHub con acceso al repositorio Enterprise (fork de lakolmena)
- El token se configura automáticamente durante la creación del proyecto

## Proceso de Creación

```bash
./forge create mi-proyecto --template odoo-enterprise
```

El sistema:
1. Te pedirá el GITHUB_TOKEN si no está configurado
2. Creará la estructura del proyecto
3. Al iniciar, descargará automáticamente los módulos Enterprise
4. Instalará web_enterprise al crear la base de datos
5. La interfaz Enterprise estará disponible inmediatamente

## Estructura de Directorios

```
proyecto/
├── enterprise/          # Módulos Enterprise (descargados automáticamente)
├── community/          # Módulos Community adicionales (opcional)
├── app/               # Tus módulos personalizados
├── config/            # Configuraciones
├── docker-compose.yml
├── Dockerfile
├── entrypoint.sh
└── odoo.conf
```

## URLs de Acceso

- **Local**: http://localhost:8026
- **HTTPS**: https://horizontic.dev.lakolmena.com
- **Longpolling**: Puerto 5461

## Credenciales

Configuradas en el archivo `.env`:
- **Usuario Admin**: admin (por defecto: admin)
- **Contraseña**: admin
- **Base de datos**: odoo

## Configuración Avanzada

### Añadir módulos Community adicionales

```bash
cd community
git clone https://github.com/OCA/web.git
git clone https://github.com/OCA/account-financial-tools.git
```

### Variables de entorno importantes

- `ODOO_VERSION`: Versión de Odoo (14-18)
- `ODOO_WITHOUT_DEMO`: Instalar sin datos demo (True/False)
- `ODOO_LANG`: Idioma por defecto
- `ODOO_TIMEZONE`: Zona horaria

## Notas Importantes

1. **Enterprise requiere licencia**: Asegúrate de tener una licencia válida de Odoo
2. **Descarga automática**: Los módulos se descargan al primer inicio del contenedor
3. **Actualizaciones**: Los módulos se mantienen en el volumen, actualiza manualmente si es necesario
4. **Token seguro**: El GITHUB_TOKEN se usa solo dentro del contenedor

## Troubleshooting

### No veo la interfaz Enterprise
- Verifica que web_enterprise esté instalado
- Limpia caché del navegador
- Reinicia sesión

### Los módulos no se descargan
- Verifica el GITHUB_TOKEN en `.env`
- Revisa los logs: `docker logs horizontic_odoo`

### Error de permisos
- Los módulos se descargan dentro del contenedor, no necesitas permisos locales