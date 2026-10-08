# Cambios de la implementacion respecto a la especificacion

Registro de lo que se implementa de forma distinta a `especificacion_tecnica_modulo_odoo.md` y `analisis_implementacion_contactos.md`, y de con que se resuelve cada requisito.

Ultima actualizacion: 2026-10-08 (revisado contra el estado actual de Odoo).

## 1. Cambios de nombres y de enfoque

| Especificacion | Implementacion | Motivo |
|---|---|---|
| `x_studio_nombre_comercial` (campo nuevo) | **`comercial`** | Lo aporta el modulo OCA `l10n_es_partner`, ya indexado (trigram) y metido en la busqueda de Many2one. No se crea campo propio |
| `mobile` (nativo) | **`mobile`** del modulo OCA `partner_mobile` | Odoo 19 elimino el campo nativo. Mismo nombre tecnico, asi que no cambia la plantilla. Se instala ademas `partner_mobile_validation` (formato del numero) |
| `type = private` | **No disponible** | Odoo 19 ya no tiene direcciones privadas. Valores: contact, invoice, delivery, other |
| Municipios INE en hoja auxiliar | **`l10n_es_toponyms` + `base_location`** | Odoo autocompleta ciudad y provincia a partir del CP. No hace falta importar la hoja Municipios |
| `bank_id` informado a mano | **Automatico** desde el IBAN | `base_bank_from_iban` (dependencia de `l10n_es_partner`) |
| `ref` sin restriccion | **`ref` unico entre empresas** | Modulo OCA `partner_ref_unique`, configurado en "Solo empresas" |
| Campos `x_studio_*` creados con Studio | **Modulo propio `horizontic_contacts`** con nombres sin prefijo (propuesta, pendiente de confirmar): `sucesor_id`, `bni_es_miembro`, `bni_region_id`, `bni_grupo_id`, `bni_estado`, `bni_actividad_id` | Versionado en git y reinstalable en otro entorno. Studio esta instalado, pero no se usa para estos campos |
| Modelos `x_region_bni`, `x_grupo_bni`, `x_actividad_bni` | **`bni.region`, `bni.grupo`, `bni.actividad`** (propuesta) | Mismo motivo |
| "6 campos personalizados" | **6 campos propios + `comercial` de OCA** | Eran 7. El nombre comercial sale de OCA, asi que el modulo propio crea 6 |

## 2. Que se resuelve con modulos existentes

### Nativos de Odoo 19 (ya instalados)
- Estructura razon social / contacto (`res.partner`, `is_company`, `parent_id`), archivado (`active`).
- Provincias, paises, validacion CIF/NIF (`base_vat`, `l10n_es`) e IBAN (`base_iban`).
- Subcuentas por partner, terminos de pago, ranks de cliente y proveedor.
- Cuentas bancarias (`res.partner.bank`).
- Facturae y TicketBAI.

### OCA rama 19.0 (instalados el 2026-10-07)

| Modulo | Repo | Que aporta |
|---|---|---|
| `l10n_es_partner` | l10n-spain | Nombre comercial `comercial` y bancos espanoles |
| `base_bank_from_iban` | community-data-files | Banco deducido del IBAN (dependencia) |
| `partner_mobile` | partner-contact | Campo `mobile` |
| `partner_mobile_validation` | partner-contact | Validacion del movil (se instala automaticamente) |
| `l10n_es_toponyms` | l10n-spain | Municipios y codigos postales de Espana (cargados: 37.867 CP) |
| `base_location`, `base_location_geonames_import` | partner-contact | Autocompletado por CP (dependencias) |
| `partner_ref_unique` | partner-contact | Referencia unica |

Repos clonados en `community/` y anadidos al `addons_path`. `community/` y `enterprise/` no se suben al repositorio; para montar el entorno hay que clonarlos:

  - `l10n-spain` (rama 19.0, commit `87dd916`): `git clone -b 19.0 https://github.com/OCA/l10n-spain.git community/l10n-spain`
  - `partner-contact` (rama 19.0, commit `b22f622`): `git clone -b 19.0 https://github.com/OCA/partner-contact.git community/partner-contact`
  - `community-data-files` (rama 19.0, commit `6866ed6`): `git clone -b 19.0 https://github.com/OCA/community-data-files.git community/community-data-files`

Dependencia Python `schwifty==2024.4.0` anadida a `requirements.txt` (imagen reconstruida).

Disponibles pero **no instalados** (decidir): `partner_vat_unique` (podria bloquear la importacion si quedan CIF repetidos), `partner_firstname` (cambia como se guarda "Apellidos, Nombre") y `partner_manual_rank`.

## 3. Desarrollo propio: modulo `horizontic_contacts`

Instalado el 2026-10-07 en `custom_modules/horizontic_contacts` (version 19.0.1.0.0, depende de `contacts` y `l10n_es_partner`).

| Requisito | Implementacion |
|---|---|
| Sucesora de archivadas | Campo `sucesor_id` (Many2one -> res.partner, solo empresas). Visible solo en empresas archivadas. No se puede borrar una empresa que es sucesora de otra |
| Catalogos BNI | Modelos `bni.region`, `bni.grupo` (con `region_id`) y `bni.actividad` (`categoria`, `descripcion`). Menu Contactos -> Configuracion -> BNI. Nombres unicos (actividad: unica por categoria). Lectura para todos los usuarios; alta y edicion para el grupo "Creacion de contactos" |
| Campos BNI | `bni_es_miembro`, `bni_region_id`, `bni_grupo_id`, `bni_estado` (activo/baja/pendiente/suspendido), `bni_actividad_id`. No se puede borrar una region, grupo o actividad en uso |
| Cascada Region -> Grupo | El desplegable de Grupo filtra por la Region elegida. Al elegir un grupo, la region se rellena sola. Si se cambia la region, se vacia un grupo que no le corresponda. Una region y un grupo incoherentes dan error al guardar o importar |
| Pestana "BNI" | Justo despues de la pestana "Contactos" en el formulario de persona, visible solo si `bni_es_miembro`. Oculta en empresas. El check "Es miembro BNI" esta debajo de "Puesto de trabajo" |
| Nombre comercial | Se mueve justo **debajo del nombre** (OCA lo ponia tras la empresa) y se anade como **columna visible en la lista** |
| Buscador de contactos | Filtro "Miembros BNI", busqueda por grupo y actividad BNI y agrupacion por region, grupo y estado BNI |

Comportamientos a tener en cuenta:
- **El nombre comercial se hereda**: OCA lo trata como dato de empresa, asi que las personas de una empresa muestran el de su empresa. Buscar por nombre comercial devuelve la empresa y sus contactos, igual que al buscar por razon social.
- `bni_es_miembro` vale `False` por defecto en fichas nuevas. Los 2.011 miembros se marcaran con la importacion.
- **No se controla** la regla BNI de "un solo miembro por capitulo y actividad" (ver `pendientes_revision.md`).
- Las etiquetas estan en castellano directamente en el codigo, sin archivos de traduccion.

## 4. Configuracion realizada

- Contenedores `horizontic_odoo` y `horizontic_postgres` con `restart: unless-stopped`: se levantan solos al reiniciar el servidor. Al recrearlos la imagen ha pasado de Odoo `19.0-20260810` a `19.0-20260926`.
- Perfil de la compania rellenado con datos publicos de horizontic.es: nombre HORIZONtic, Ugartebeitia 7, 3ª Planta, Dpto. 6, 48903 Barakaldo (Bizkaia), +34 846 664 231, administracion@horizontic.es, https://horizontic.es, y el logo.
- `partner_ref_unique` en modo "Solo empresas".
- `entrypoint.sh`: el `addons_path` del servidor lo construye el entrypoint, que ignora `odoo.conf`. Ahora incluye `custom_modules/` (si hay modulos) y cada repo clonado en `community/`. Antes no cargaba ni los repos OCA ni los modulos propios.

## 5. Configuracion nativa

Hecho por el usuario (comprobado el 2026-10-08):
- Plan contable **`es_full`** (PGC completo, no el PYMES que daba por hecho la especificacion), moneda EUR, 745 cuentas de 6 digitos.
- Compras (`purchase`) instalado.
- Studio (`web_studio`) instalado.
- Euskera (`eu_ES`) activo.
- CIF de la compania informado (A95921060).

Pendiente: crear las subcuentas legacy 43/41 cuando lleguen los datos.
