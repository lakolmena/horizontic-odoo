# Pendientes de revision

Dudas e incoherencias detectadas en la documentacion del cliente que hay que aclarar antes de implementar.

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

**A confirmar con el cliente:** si son 7 campos y el "6" es una errata, o si alguno de los campos sobra.

## 2. Campo `mobile` no existe en Odoo 19

- **Documento:** `especificacion_tecnica_modulo_odoo.md`, apartados 3.3 y 4.2
- **Estado:** Resuelto
- **Detectado:** 2026-10-07

La especificacion usa el campo nativo `mobile`, pero Odoo 19 lo elimino de `res.partner` (solo queda `phone`). **Resuelto (2026-10-07):** se ha instalado el modulo OCA `partner_mobile`, que recupera el campo con el mismo nombre.

## 3. Tipo de direccion `private` no existe en Odoo 19

- **Documento:** `especificacion_tecnica_modulo_odoo.md`, apartado 4.1
- **Estado:** Pendiente
- **Detectado:** 2026-10-07

Los valores validos de `type` son: contact, invoice, delivery, other (y facturae_ac con l10n_es_edi_facturae). **A confirmar:** si algun contacto de la plantilla viene con `private` y a que tipo se pasa.

## 4. Nombres tecnicos de los campos personalizados

- **Documento:** `especificacion_tecnica_modulo_odoo.md`, apartados 3 y 5
- **Estado:** Pendiente
- **Detectado:** 2026-10-07

Los nombres `x_studio_*` solo salen asi si se crean con Studio. Si se usa el modulo OCA `l10n_es_partner`, el nombre comercial se llama `comercial`. Si se hace un modulo propio, lo normal es usar nombres sin prefijo (p. ej. `bni_region_id`). **Propuesta (2026-10-07):** nombre comercial = `comercial` (OCA); resto en modulo propio: `sucesor_id`, `bni_es_miembro`, `bni_region_id`, `bni_grupo_id`, `bni_estado`, `bni_actividad_id`, modelos `bni.region`, `bni.grupo`, `bni.actividad` (ver `cambios_implementacion.md`). **A confirmar:** si la plantilla Excel puede adaptarse a estos nombres.

## 5. Plan contable y modulo de Compras

- **Documento:** `especificacion_tecnica_modulo_odoo.md`, apartados 3.4 y 8
- **Estado:** Resuelto en parte
- **Detectado:** 2026-10-07

La BD actual tiene cargado el plan contable **generico** (`generic_coa`), no el PGC PYMES, y el modulo `purchase` no esta instalado. Hay que corregirlo antes de crear las subcuentas legacy 43xxxxxx / 41xxxxxx. La compania tambien esta sin configurar ("My Company", sin NIF). **A confirmar:** datos fiscales de la compania y el formato exacto de las subcuentas legacy (numero de digitos).

**Actualizacion (2026-10-07):** el usuario ha cargado el plan `es_full` (PGC completo) en EUR, ha instalado Compras y ha configurado la compania. Queda pendiente el formato de las subcuentas legacy (numero de digitos).

## 6. CIF y datos fiscales de HORIZONtic

- **Estado:** Resuelto
- **Detectado:** 2026-10-07

El perfil de la compania se ha rellenado con los datos publicos de horizontic.es (direccion, telefono, email, web y logo), pero **el CIF no esta publicado**. En la web aparece "HORIZONTIC (TICSA)", sin la razon social completa. **A pedir al cliente:** CIF, razon social exacta y datos del Registro Mercantil.

**Actualizacion (2026-10-07):** el usuario ha informado el CIF de la compania en Odoo.

## 7. Municipios: geonames frente a nomenclatura INE

- **Documento:** `especificacion_tecnica_modulo_odoo.md`, apartado 3.2
- **Estado:** Pendiente
- **Detectado:** 2026-10-07

La especificacion habla de 8.131 municipios INE. `l10n_es_toponyms` carga desde geonames 37.867 CP y 36.687 localidades, cuyos nombres no siempre coinciden con el municipio INE (pueden ser barrios o pedanias). El campo `city` de la plantilla se importa como texto, asi que no bloquea la importacion. **A confirmar:** si basta con el texto de la plantilla o se quiere enlazar cada ficha a su CP (`zip_id`).

## 8. Modulos OCA opcionales sin instalar

- **Estado:** Pendiente
- **Detectado:** 2026-10-07

Estan descargados pero sin instalar: `partner_vat_unique` (CIF unico; podria bloquear la carga si quedan duplicados), `partner_firstname` (separa nombre y apellidos) y `partner_manual_rank` (casillas cliente/proveedor). **A decidir** tras ver la calidad de los datos.

## 9. Regla BNI "un miembro por capitulo y actividad"

- **Documento:** `especificacion_tecnica_modulo_odoo.md`, apartado 5.1
- **Estado:** Pendiente
- **Detectado:** 2026-10-07

La especificacion recuerda que BNI solo admite un miembro por capitulo y actividad, pero no pide que Odoo lo controle, y el modulo no lo hace. Se podria anadir un aviso o un bloqueo, por ejemplo solo para miembros con estado "activo". **A confirmar:** si se quiere el control y si debe bloquear o solo avisar. Un bloqueo podria parar la importacion si los datos historicos tienen repetidos.
