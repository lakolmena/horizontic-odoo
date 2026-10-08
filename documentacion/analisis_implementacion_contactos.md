# Analisis de implementacion - Modulo Contactos (HORIZONtic)

Analisis de la especificacion `especificacion_tecnica_modulo_odoo.md` frente a la instalacion.
Analisis inicial: 2026-10-07. Estado revisado: 2026-10-08.

El detalle de lo implementado y de lo que difiere de la especificacion esta en `cambios_implementacion.md`. Las dudas abiertas, en `pendientes_revision.md`.

## 1. Que pide la especificacion

La especificacion afecta a un unico modelo de negocio (`res.partner`) mas `res.partner.bank`. Todo cuelga del modulo **Contactos**.

### 1.1 Campos nativos (solo configuracion / importacion)

| Bloque | Campos | Estado en Odoo 19 |
|---|---|---|
| Identificacion | `ref`, `name`, `company_type`, `vat`, `comment` | Existen |
| Direccion | `street`, `street2`, `zip`, `city`, `state_id`, `country_id` | Existen (52 provincias ES cargadas) |
| Comunicacion | `phone`, `email`, `website`, `lang` | Existen |
| Comunicacion | `mobile` | Lo aporta el modulo OCA `partner_mobile` (Odoo 19 elimino el campo nativo) |
| Contactos | `parent_id`, `function`, `type` | Existen. **`type=private` ya no existe** (valores: contact, invoice, delivery, other, facturae_ac) |
| Clasificacion | `customer_rank`, `supplier_rank`, `active` | Existen |
| Contabilidad | `property_account_receivable_id`, `property_account_payable_id`, `property_payment_term_id` | Existen ("Pago inmediato" existe) |
| Bancos | `acc_number`, `bank_id`, `currency_id`, `allow_out_payment`, `sequence`, `partner_id` | Existen |

### 1.2 Campos personalizados

| Campo en la especificacion | Implementado como | Con |
|---|---|---|
| `x_studio_nombre_comercial` | `comercial` | OCA `l10n_es_partner` |
| `x_studio_sucesor_id` | `sucesor_id` | `horizontic_contacts` |
| `x_studio_es_miembro_bni` | `bni_es_miembro` | `horizontic_contacts` |
| `x_studio_region_bni` | `bni_region_id` | `horizontic_contacts` |
| `x_studio_grupo_bni` | `bni_grupo_id` | `horizontic_contacts` |
| `x_studio_estado_bni` | `bni_estado` | `horizontic_contacts` |
| `x_studio_actividad_bni` | `bni_actividad_id` | `horizontic_contacts` |

Son **7 campos**, no 6 como dice la especificacion (ver `pendientes_revision.md`).

### 1.3 Modelos auxiliares

| Especificacion | Implementado como | Registros previstos | Cargados |
|---|---|---|---|
| `x_region_bni` | `bni.region` | 4 | 0 |
| `x_grupo_bni` | `bni.grupo` | 37 | 0 |
| `x_actividad_bni` | `bni.actividad` | 512 | 0 |

### 1.4 Vistas

Implementadas en `horizontic_contacts`: pestana "BNI" condicional, cascada Region -> Grupo, nombre comercial debajo del nombre y como columna de la lista. La busqueda rapida y la creacion rapida con nombre comercial las cubre OCA.

## 2. Estado actual de la instalacion (2026-10-08)

| Elemento | Estado |
|---|---|
| Version | **Odoo 19.0 Enterprise**, imagen `19.0-20260926`; repo enterprise en la rama 19.0 |
| Contenedores | `horizontic_odoo` y `horizontic_postgres` funcionando, con `restart: unless-stopped` |
| Base de datos | `odoo`, creada el 2026-10-01. 137 modulos instalados |
| Compania | HORIZONtic, CIF A95921060, Ugartebeitia 7, 3ª Planta, Dpto. 6, 48903 Barakaldo, con logo |
| Plan contable | **`es_full`** (PGC completo), moneda EUR, 745 cuentas de 6 digitos |
| Idiomas | `es_ES` y `eu_ES` |
| Datos | Sin datos de clientes: 6 partners del sistema, 0 cuentas bancarias, 0 registros BNI, 0 asientos |
| Codigos postales | 37.867 CP y 36.687 localidades de Espana (`l10n_es_toponyms`) |
| Repos OCA | `community/`: l10n-spain, partner-contact y community-data-files (rama 19.0) |
| Modulo propio | `custom_modules/horizontic_contacts` 19.0.1.0.0, instalado |

### Modulos relevantes instalados

- **Nativos y Enterprise:** `base`, `contacts`, `contacts_enterprise`, `account`, `account_accountant`, `account_followup`, `base_vat`, `base_iban`, `l10n_es`, `l10n_es_edi_facturae`, `l10n_es_edi_tbai`, `l10n_es_reports*`, `sale`, `sale_management`, `purchase`, `crm`, `web_studio`, `partner_autocomplete`, `phone_validation`.
- **OCA:** `l10n_es_partner`, `base_bank_from_iban`, `partner_mobile`, `partner_mobile_validation`, `l10n_es_toponyms`, `base_location`, `base_location_geonames_import`, `partner_ref_unique` (y `base_address_extended` como dependencia nativa).
- **Propio:** `horizontic_contacts`.

### Modulos de la especificacion (apartado 8)

| Modulo | Estado |
|---|---|
| `base`, `contacts` | Instalados |
| `l10n_es` | Instalado (plan `es_full`) |
| `l10n_es_edi_facturae` | Instalado |
| `l10n_es_edi_tbai` | Instalado |
| `account` | Instalado |
| `sale`, `purchase` | Instalados |
| `studio` | Instalado (`web_studio`). No se usa para los campos de la especificacion: van en el modulo propio |

## 3. Que se resuelve con configuracion / nativo

| Requisito | Solucion nativa |
|---|---|
| Razones sociales / contactos / vinculo | `res.partner` con `company_type` y `parent_id` |
| Provincias | 52 provincias cargadas por `base` |
| Validacion CIF/NIF | `base_vat` + `l10n_es` |
| Validacion IBAN | `base_iban` |
| Subcuentas 43/41 por partner | Propiedades `property_account_*` de `account`. Hay que crear las subcuentas legacy antes de importar |
| Termino de pago "Pago inmediato" | Existe |
| Facturae / TicketBAI | `l10n_es_edi_facturae`, `l10n_es_edi_tbai` |
| Ventas / compras | `sale` y `purchase` |
| Archivadas | `active=False` nativo |
| Importacion por fases con External ID | Importador nativo de Odoo (columnas `id`, `parent_id/id`, `partner_id/id`) |
| Busqueda por razon social, CIF y ref | Nativo (`_rec_names_search` incluye `complete_name`, `email`, `ref`, `vat`) |

Lo que **no** cubre el nativo: nombre comercial, movil, campo sucesora y bloque BNI. Los dos primeros los cubre OCA y los otros dos el modulo propio.

## 4. Modulos OCA (rama 19.0)

| Necesidad | Modulo OCA | Repo | Estado |
|---|---|---|---|
| Nombre comercial | `l10n_es_partner` | l10n-spain | Instalado. Campo `comercial` (indice trigram), en la busqueda por nombre y en la creacion rapida. Anade datos de bancos espanoles (listado del Banco de España sin cargar) |
| Movil | `partner_mobile` | partner-contact | Instalado |
| Municipios / CP | `l10n_es_toponyms` + `base_location` | l10n-spain / partner-contact | Instalados y CP cargados |
| Referencia unica | `partner_ref_unique` | partner-contact | Instalado, modo "Solo empresas" |
| CIF unico | `partner_vat_unique` | partner-contact | Descargado, sin instalar |
| "Apellidos, Nombre" | `partner_firstname` | partner-contact | Descargado, sin instalar |
| Cliente/proveedor manual | `partner_manual_rank` | partner-contact | Descargado, sin instalar |
| Quick create controlado | `web_m2x_options` | web | No descargado (repo `web` no clonado) |
| Relaciones entre partners | `partner_multi_relation` | partner-contact | Descartado: la sucesora se hace con un campo simple |

**No hay modulo OCA para el bloque BNI**, y el modulo nativo `membership` ya no existe en la 19. Se ha hecho a medida en `horizontic_contacts`.

## 5. Resumen

1. **Alcance:** un modulo funcional (Contactos) con 7 campos nuevos, 3 modelos auxiliares, una pestana condicional y ajustes de vista para el nombre comercial. **Implementado.**
2. **Reparto:** nombre comercial y movil con OCA; sucesora, bloque BNI y ajustes de vista con el modulo propio `horizontic_contacts`.
3. **Incompatibilidad con Odoo 19 que sigue abierta:** `type=private` ya no existe.
4. **Falta para la migracion:** los datos del cliente (plantilla Excel y subcuentas legacy) y cerrar las decisiones de `pendientes_revision.md`.
