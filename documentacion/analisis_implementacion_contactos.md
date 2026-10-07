# Analisis de implementacion - Modulo Contactos (HORIZONtic)

Analisis de la especificacion `especificacion_tecnica_modulo_odoo.md` frente a la instalacion actual.
Fecha del analisis: 2026-10-07.

## 1. Que hay que implementar

La especificacion afecta a un unico modelo de negocio (`res.partner`) mas `res.partner.bank`. Todo cuelga del modulo **Contactos**.

### 1.1 Campos nativos (solo configuracion / importacion)

| Bloque | Campos | Estado en Odoo 19 |
|---|---|---|
| Identificacion | `ref`, `name`, `company_type`, `vat`, `comment` | Existen |
| Direccion | `street`, `street2`, `zip`, `city`, `state_id`, `country_id` | Existen (52 provincias ES ya cargadas) |
| Comunicacion | `phone`, `email`, `website`, `lang` | Existen |
| Comunicacion | **`mobile`** | **NO existe en Odoo 19** (se elimino en la 19.0) |
| Contactos | `parent_id`, `function`, `type` | Existen. **`type=private` ya no existe** (valores: contact, invoice, delivery, other, facturae_ac) |
| Clasificacion | `customer_rank`, `supplier_rank`, `active` | Existen |
| Contabilidad | `property_account_receivable_id`, `property_account_payable_id`, `property_payment_term_id` | Existen ("Pago inmediato" ya existe) |
| Bancos | `acc_number`, `bank_id`, `currency_id`, `allow_out_payment`, `sequence`, `partner_id` | Existen |

### 1.2 Campos personalizados (a crear)

| Campo | Tipo | Donde |
|---|---|---|
| `x_studio_nombre_comercial` | Char indexado, en busqueda, lista, formulario y quick create | Razones sociales |
| `x_studio_sucesor_id` | Many2one -> res.partner | Razones sociales archivadas |
| `x_studio_es_miembro_bni` | Boolean | Contactos |
| `x_studio_region_bni` | Many2one -> x_region_bni | Contactos |
| `x_studio_grupo_bni` | Many2one -> x_grupo_bni (filtrado por region) | Contactos |
| `x_studio_estado_bni` | Selection (activo/baja/pendiente/suspendido) | Contactos |
| `x_studio_actividad_bni` | Many2one -> x_actividad_bni | Contactos |

Son **7 campos**, no 6 (ver `pendientes_revision.md`).

### 1.3 Modelos auxiliares (a crear)

- `x_region_bni` (name) - 4 registros
- `x_grupo_bni` (name, region_id) - 37 registros
- `x_actividad_bni` (name, categoria, descripcion) - 512 registros

### 1.4 Vistas

- Pestana "BNI" en el formulario de contacto persona, invisible si `not x_studio_es_miembro_bni`.
- Nombre comercial debajo de `name`, columna en la lista, en la busqueda rapida y en quick create.
- Desplegables en cascada Region -> Grupo.

## 2. Estado de la instalacion

| Elemento | Estado |
|---|---|
| Version | **Odoo 19.0 Enterprise** (imagen `19.0-20260810`, repo enterprise rama 19.0, commit de 2026-01-22) |
| Contenedores | `horizontic_odoo` y `horizontic_postgres` **parados** (Exited hace 5 dias) |
| Base de datos | `odoo`, creada el 2026-10-01 |
| Datos | Practicamente vacia: 6 partners del sistema, 0 cuentas bancarias, 0 campos/modelos `x_` |
| Compania | Sin configurar: nombre "My Company", sin NIF |
| **Plan contable** | **`generic_coa`** (generico, 51 cuentas de 6 digitos). **No esta cargado el PGC PYMES (`es_pymes`)** aunque `l10n_es` esta instalado |
| Idiomas | Solo `es_ES` activo (falta `eu_ES`) |
| `custom_modules/`, `community/`, `app/` | Vacios (sin modulos propios ni OCA) |
| `requirements.txt` | Preparado para OCA (packaging, paramiko, pysftp, cryptography) |

### Modulos relevantes instalados

`base`, `contacts`, `contacts_enterprise`, `account`, `account_accountant`, `account_followup`, `base_vat`, `base_iban`, `l10n_es`, `l10n_es_edi_facturae`, `l10n_es_edi_tbai`, `l10n_es_reports*`, `sale`, `sale_management`, `crm`, `partner_autocomplete`, `phone_validation`.

### Modulos requeridos por la especificacion que faltan

| Modulo | Estado | Comentario |
|---|---|---|
| `purchase` | **No instalado** | La especificacion lo marca como imprescindible |
| `web_studio` | **No instalado** (disponible en enterprise) | Recomendado en la especificacion |

## 3. Que se resuelve con configuracion / nativo

| Requisito | Solucion nativa |
|---|---|
| Razones sociales / contactos / vinculo | `res.partner` con `company_type` y `parent_id` |
| Provincias | 52 provincias ya cargadas por `base` |
| Validacion CIF/NIF | `base_vat` + `l10n_es` (instalados) |
| Validacion IBAN | `base_iban` (instalado) |
| Subcuentas 43/41 por partner | Propiedades `property_account_*` de `account`. Hay que **cargar PGC PYMES** y crear las subcuentas legacy antes de importar |
| Termino de pago "Pago inmediato" | Ya existe |
| Euskera | Activar idioma `eu_ES` en Ajustes |
| Facturae / TicketBAI | Ya instalados (`l10n_es_edi_facturae`, `l10n_es_edi_tbai`) |
| Ventas / compras | `sale` instalado; **instalar `purchase`** |
| Archivadas | `active=False` nativo |
| Importacion por fases con External ID | Importador nativo de Odoo (columnas `id`, `parent_id/id`, `partner_id/id`) |
| Campos personalizados, modelos auxiliares y pestana BNI | Posible con **Studio** (incluido en Enterprise). Alternativa: modulo propio |
| Busqueda por razon social, CIF y ref | Nativo (`_rec_names_search` incluye `complete_name`, `email`, `ref`, `vat`) |

Lo que **no** cubre el nativo: `mobile` (eliminado en la 19), nombre comercial en la busqueda rapida y en quick create, campo sucesora, bloque BNI.

## 4. Que se puede cubrir con OCA (rama 19.0)

Ninguno esta presente hoy en la instalacion. Todos los modulos listados existen en la rama 19.0 de OCA.

| Necesidad | Modulo OCA | Repo | Comentario |
|---|---|---|---|
| **Nombre comercial** | `l10n_es_partner` | l10n-spain | Anade el campo `comercial` (Char, indice trigram), lo mete en la busqueda por nombre y permite un patron de nombre mostrado. Tambien anade datos de bancos espanoles. Depende de `base_bank_from_iban` (community-data-files). **El campo se llama `comercial`, no `x_studio_nombre_comercial`** |
| **Movil** | `partner_mobile` | partner-contact | Recupera el campo `mobile`, eliminado en la 19.0 |
| Municipios INE / CP | `l10n_es_toponyms` + `base_location` | l10n-spain / partner-contact | Municipios y CP de Espana con autocompletado ciudad/provincia desde el CP. Depende de `base_location_geonames_import` |
| Referencia unica | `partner_ref_unique` | partner-contact | Garantiza `ref` unico (0001..1207) |
| CIF unico | `partner_vat_unique` | partner-contact | Evita duplicados por NIF (la BBDD tiene historico de duplicados) |
| "Apellidos, Nombre" | `partner_firstname` | partner-contact | Opcional: separa nombre y apellidos manteniendo el formato |
| Cliente/proveedor manual | `partner_manual_rank` | partner-contact | Opcional: checks "Es cliente / Es proveedor" en vez de ranks numericos |
| Quick create controlado | `web_m2x_options` | web | Opcional: controlar creacion rapida/edicion en Many2one |
| Relaciones entre partners | `partner_multi_relation` | partner-contact | Alternativa generica para "sucesora", probablemente excesiva |

**No hay modulo OCA para el bloque BNI** (regiones, capitulos, actividades, estado de miembro). Tampoco existe ya el modulo nativo `membership` en la 19, y no encajaria porque esta orientado a cuotas y productos. Hay que hacerlo a medida.

## 5. Resumen y propuesta

1. **Alcance:** un modulo funcional (Contactos) con 7 campos nuevos, 3 modelos auxiliares, una pestana condicional y ajustes de vista para el nombre comercial.
2. **La instalacion esta casi en blanco:** Odoo 19 Enterprise, BD sin datos, compania sin configurar y **plan contable generico en lugar de PGC PYMES**. Hay que corregirlo antes de crear las subcuentas legacy 43/41.
3. **Faltan modulos de la especificacion:** `purchase` (imprescindible) y, si se usa, `web_studio`.
4. **La especificacion esta escrita para una version anterior a la 19:** `mobile` y `type=private` ya no existen.
5. **Propuesta tecnica:**
   - Nativo + configuracion: PGC PYMES, `purchase`, idioma `eu_ES`, subcuentas legacy.
   - OCA 19.0: `l10n_es_partner` (nombre comercial), `partner_mobile`, `l10n_es_toponyms` + `base_location` (municipios), y como opcionales `partner_ref_unique` y `partner_vat_unique`.
   - Modulo propio `horizontic_contacts` en `custom_modules/`: sucesora, bloque BNI (3 modelos + 5 campos), pestana condicional, dominio Region -> Grupo, datos de catalogos y permisos. Se prefiere a Studio porque queda versionado en git y se puede reinstalar en otro entorno.
6. **Decisiones abiertas** (anotadas en `pendientes_revision.md`): nombres tecnicos de los campos (`x_studio_*` frente a `comercial` y nombres de modulo propio), cuantos campos son, `mobile` y `private`.
