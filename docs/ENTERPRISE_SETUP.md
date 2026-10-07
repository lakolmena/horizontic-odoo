# Configuración de Odoo Enterprise en FORGE

## Proceso de Creación Automático

Cuando creas un proyecto Odoo Enterprise con FORGE, el sistema automáticamente:

1. **Descarga los módulos Enterprise** antes de iniciar los contenedores
2. **Configura el addons_path** para incluir los módulos Enterprise
3. **Instala el módulo web_enterprise** al inicializar la base de datos

## Requisitos

- Token de GitHub con acceso al repositorio Enterprise
- El token debe configurarse en el archivo `.env` como `GITHUB_TOKEN`

## Crear un Proyecto Odoo Enterprise

```bash
./forge create mi-proyecto --template odoo-enterprise
```

El sistema te pedirá el token de GitHub si no está configurado.

## Características del Template

- **Descarga automática de módulos**: El script `post-create.sh` se ejecuta automáticamente
- **661+ módulos Enterprise** disponibles
- **Tema Enterprise** (web_enterprise) incluido
- **PostgreSQL dedicado** para cada proyecto
- **Selector de base de datos** habilitado por defecto

## Estructura del Proyecto

```
mi-proyecto/
├── enterprise/          # Módulos Enterprise (descargados automáticamente)
├── community/           # Módulos de la comunidad personalizados
├── app/                 # Módulos propios
├── config/              # Configuraciones
├── docker-compose.yml   # Configuración de contenedores
├── odoo.conf           # Configuración de Odoo
├── init-enterprise.sh   # Script para descargar módulos (ejecutado automáticamente)
└── entrypoint.sh       # Script de inicio personalizado
```

## Acceso y Credenciales

- **URL Local**: http://localhost:{PUERTO}
- **URL HTTPS**: https://{proyecto}.dev.lakolmena.com
- **Usuario admin**: Configurado en `.env` (por defecto: admin)
- **Contraseña**: Configurada en `.env`

## Notas Importantes

1. Los módulos Enterprise se descargan del fork de lakolmena
2. El tema Enterprise (interfaz moderna) se activa automáticamente
3. Para proyectos existentes sin Enterprise, ejecuta manualmente:
   ```bash
   cd /path/to/project
   ./init-enterprise.sh
   docker-compose restart
   ```

## Troubleshooting

Si no ves el tema Enterprise:
1. Verifica que web_enterprise esté instalado
2. Limpia caché del navegador
3. Reinicia sesión

Si los módulos no se descargan:
1. Verifica el GITHUB_TOKEN
2. Ejecuta manualmente: `./init-enterprise.sh`
3. Revisa los logs: `docker logs {proyecto}_odoo`