# Pendientes de revision

Dudas e incoherencias detectadas en la documentacion del cliente que hay que aclarar con el cliente antes de la migracion.

## 1. Numero de campos personalizados en res.partner

- **Documento:** `especificacion_tecnica_modulo_odoo.md` (Especificacion tecnica - Modulo Contactos Odoo, 2026-09-22)
- **Estado:** Pendiente
- **Detectado:** 2026-10-07

**Incoherencia:** el documento habla de **6 campos personalizados** (apartado "Alcance del documento" y Paso 0, punto 2 del plan de importacion), pero en las tablas aparecen **7 campos** marcados como a crear:

| # | Campo | Apartado |
|---|---|---|
| 1 | `x_studio_nombre_comercial` | 3.1 |
| 2 | `x_studio_sucesor_id` | 3.4 |
| 3 | `x_studio_es_miembro_bni` | 5.1 |
| 4 | `x_studio_region_bni` | 5.1 |
| 5 | `x_studio_grupo_bni` | 5.1 |
| 6 | `x_studio_estado_bni` | 5.1 |
| 7 | `x_studio_actividad_bni` | 5.1 |

Se han implementado los 7: el nombre comercial con el modulo OCA `l10n_es_partner` y los otros 6 en `horizontic_contacts`. **A confirmar con el cliente:** si el "6" es una errata o si alguno de los campos sobra.

## 2. Tipo de direccion `private` no existe en Odoo 19

- **Documento:** `especificacion_tecnica_modulo_odoo.md`, apartado 4.1
- **Estado:** Pendiente
- **Detectado:** 2026-10-07

Los valores validos de `type` son: contact, invoice, delivery, other (y facturae_ac con l10n_es_edi_facturae). **A confirmar:** si algun contacto de la plantilla viene con `private` y a que tipo se pasa.

## 3. Nombres tecnicos de los campos personalizados

- **Documento:** `especificacion_tecnica_modulo_odoo.md`, apartados 3 y 5
- **Estado:** Pendiente
- **Detectado:** 2026-10-07

Los nombres `x_studio_*` solo salen asi si se crean con Studio. Si se usa el modulo OCA `l10n_es_partner`, el nombre comercial se llama `comercial`. Si se hace un modulo propio, lo normal es usar nombres sin prefijo (p. ej. `bni_region_id`). **Implementado (2026-10-07) con estos nombres:** nombre comercial = `comercial` (OCA); resto en el modulo propio: `sucesor_id`, `bni_es_miembro`, `bni_region_id`, `bni_grupo_id`, `bni_estado`, `bni_actividad_id`, y modelos `bni.region`, `bni.grupo`, `bni.actividad` (ver `cambios_implementacion.md`). **A confirmar:** si la plantilla Excel puede adaptarse a estos nombres.

## 4. Formato de las subcuentas legacy

- **Documento:** `especificacion_tecnica_modulo_odoo.md`, apartado 3.4
- **Estado:** Pendiente
- **Detectado:** 2026-10-07

Hay que crear las subcuentas legacy 43xxxxxx (clientes) y 41xxxxxx (proveedores) en el plan contable antes de importar las razones sociales. El plan cargado (`es_full`) trabaja con cuentas de 6 digitos; la especificacion habla de subcuentas de 8 (43xxxxxx). Odoo admite codigos de distinta longitud, pero conviene que sean homogeneos. **A confirmar:** el formato exacto de las subcuentas (numero de digitos) y el listado con el titular de cada una.

## 5. Municipios: geonames frente a nomenclatura INE

- **Documento:** `especificacion_tecnica_modulo_odoo.md`, apartado 3.2
- **Estado:** Pendiente
- **Detectado:** 2026-10-07

La especificacion habla de 8.131 municipios INE. `l10n_es_toponyms` carga desde geonames 37.867 CP y 36.687 localidades, cuyos nombres no siempre coinciden con el municipio INE (pueden ser barrios o pedanias). El campo `city` de la plantilla se importa como texto, asi que no bloquea la importacion. **A confirmar:** si basta con el texto de la plantilla o se quiere enlazar cada ficha a su CP (`zip_id`).

## 6. Modulos OCA opcionales sin instalar

- **Estado:** Pendiente
- **Detectado:** 2026-10-07

Estan descargados pero sin instalar: `partner_vat_unique` (CIF unico; podria bloquear la carga si quedan duplicados), `partner_firstname` (separa nombre y apellidos) y `partner_manual_rank` (casillas cliente/proveedor). **A decidir** tras ver la calidad de los datos.

## 7. Regla BNI "un miembro por capitulo y actividad"

- **Documento:** `especificacion_tecnica_modulo_odoo.md`, apartado 5.1
- **Estado:** Pendiente
- **Detectado:** 2026-10-07

La especificacion recuerda que BNI solo admite un miembro por capitulo y actividad, pero no pide que Odoo lo controle, y el modulo no lo hace. Se podria anadir un aviso o un bloqueo, por ejemplo solo para miembros con estado "activo". **A confirmar:** si se quiere el control y si debe bloquear o solo avisar. Un bloqueo podria parar la importacion si los datos historicos tienen repetidos.
