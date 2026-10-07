# Especificacion tecnica - Modulo Contactos Odoo

*HORIZONtic - documento para el proveedor implantador*

- **Cliente:** HORIZONtic (Barakaldo, Bizkaia)
- **Actividad:** Consultoria y franquicia regional BNI en Euskadi y Navarra
- **Fecha:** 2026-09-22
- **Contacto:** jonatan.medina@horizontic.es
- **Objetivo:** Detallar los campos que el modulo estandar de Contactos (res.partner) necesita cubrir para la migracion de la BBDD actual y para la operativa posterior. Incluye campos nativos y personalizados a crear.

---

## 1. Contexto y volumenes

HORIZONtic dispone de una base de datos historica de 1.207 razones sociales (clientes activos, proveedores y sociedades archivadas) y 2.025 contactos personales. El 99% de los contactos son miembros BNI, ya que HORIZONtic es franquicia regional en Euskadi y Navarra.

| Registro | Modelo Odoo | Cantidad |
|---|---|---|
| `Razones sociales activas` | res.partner | 1.174 |
| `Razones sociales archivadas` | res.partner (active=False) | 33 |
| `Contactos personales` | res.partner (type=contact) | 2.025 |
| `Cuentas bancarias` | res.partner.bank | a completar antes de migrar |
| `TOTAL res.partner` | - | 3.232 |

### Alcance del documento

Describe (a) los campos nativos de res.partner a utilizar, (b) los 6 campos personalizados y 3 modelos auxiliares a crear, (c) la configuracion de vista especifica y (d) el modelo de importacion en fases.

## 2. Estructura general del modelo

Odoo utiliza un unico modelo (res.partner) para personas juridicas y fisicas. La diferencia se establece con company_type y con parent_id (enlaza un contacto persona con su razon social matriz).

| Entidad | Modelo Odoo | Descripcion |
|---|---|---|
| `Razon social` | res.partner (company_type=company) | Persona juridica con CIF, subcuenta contable y customer/supplier_rank |
| `Contacto personal` | res.partner (company_type=person) | Persona fisica vinculada a una razon social via parent_id |
| `Cuenta bancaria` | res.partner.bank | Vinculada a un res.partner mediante partner_id |

## 3. Campos para Razones Sociales

### 3.1 Identificacion y datos fiscales

| Campo Odoo | Etiqueta UI | Tipo | Descripcion | Origen |
|---|---|---|---|---|
| `id` | - | External ID | Identificador tecnico. Formato hzn.partner_NNNN. Usado para importar y resolver relaciones entre hojas. | Nativo |
| `ref` | Referencia | Char | Referencia comercial visible (0001..1207) por antiguedad. Identifica al cliente por numero. | Nativo |
| `name` | Nombre | Char | Razon social completa (denominacion oficial en Registro Mercantil). | Nativo |
| `x_studio_nombre_comercial` | Nombre comercial | Char (indexado) | Marca comercial visible. Puede diferir de la razon social. CRITICO para busquedas. | A CREAR |
| `company_type` | Tipo | Selection | Valor fijo "company". | Nativo |
| `vat` | NIF | Char | CIF/NIF sin separadores. Validacion con l10n_es. | Nativo |
| `comment` | Notas internas | Html | Notas libres. | Nativo |

### 3.2 Direccion postal

| Campo Odoo | Etiqueta UI | Tipo | Descripcion |
|---|---|---|---|
| `street` | Direccion linea 1 | Char | Via publica y numero. |
| `street2` | Direccion linea 2 | Char | Complementos: piso, puerta, apartado, poligono. |
| `zip` | Codigo postal | Char | Como texto (preserva ceros iniciales). |
| `city` | Localidad | Char | Municipio segun nomenclatura INE oficial. |
| `state_id` | Provincia | Many2one -> res.country.state | 52 provincias precargadas en base. |
| `country_id` | Pais | Many2one -> res.country | base.es por defecto. |

*Nota: la plantilla entrega provincia y municipio como desplegables dependientes. Los 8.131 municipios INE incluidos en hoja auxiliar.*

### 3.3 Comunicacion

| Campo Odoo | Etiqueta UI | Tipo | Descripcion |
|---|---|---|---|
| `phone` | Telefono | Char | Telefono fijo. |
| `mobile` | Movil | Char | Telefono movil. |
| `email` | Email | Char | Con validacion de formato. |
| `website` | Sitio web | Char | URL corporativa. |
| `lang` | Idioma | Selection | es_ES por defecto; eu_ES disponible. |

### 3.4 Clasificacion comercial y contable

| Campo Odoo | Etiqueta UI | Tipo | Descripcion |
|---|---|---|---|
| `customer_rank` | - | Integer | 1 si es cliente. Habilita para Ventas. |
| `supplier_rank` | - | Integer | 1 si es proveedor. Habilita para Compras. |
| `active` | Activo | Boolean | TRUE por defecto. FALSE = ficha archivada. |
| `property_account_receivable_id` | Cuenta a cobrar | Many2one -> account.account | Subcuenta cliente. HORIZONtic mantiene subcuentas legacy 43xxxxxx. El implantador debe garantizar que existen. |
| `property_account_payable_id` | Cuenta a pagar | Many2one -> account.account | Subcuenta proveedor (41xxxxxx). Mismo criterio. |
| `property_payment_term_id` | Terminos pago | Many2one -> account.payment.term | Por defecto "Pago inmediato". |
| `x_studio_sucesor_id` | Sucesora | Many2one -> res.partner | Solo en archivadas. Apunta a la razon social activa que la reemplaza (33 casos). A CREAR. |

*Nota contable: se conservan las subcuentas legacy (43xxxxxx clientes / 41xxxxxx proveedores) para preservar trazabilidad con el historico. El implantador debe crearlas en el plan contable antes de importar.*

## 4. Campos para Contactos personales

Los contactos son personas fisicas enganchadas a una razon social mediante parent_id. Comparten campos de identificacion, direccion y comunicacion con las razones sociales. Anaden el bloque BNI.

### 4.1 Identificacion y vinculo

| Campo Odoo | Etiqueta UI | Tipo | Descripcion |
|---|---|---|---|
| `id` | - | External ID | hzn.contact_NNNN. |
| `name` | Nombre | Char | Apellidos, Nombre (formato HORIZONtic). |
| `company_type` | Tipo | Selection | Fijo "person". |
| `parent_id` | Empresa | Many2one -> res.partner | Razon social. Vacio para contactos sueltos. |
| `type` | Tipo direccion | Selection | contact por defecto. Alternativas: invoice, delivery, other, private. |
| `function` | Cargo | Char | Puesto en la empresa. |
| `vat` | DNI | Char | Documento de la persona fisica. |

### 4.2 Comunicacion, direccion y estado

Los campos street, street2, zip, city, state_id, country_id, phone, mobile, email, lang, active son identicos a los de Razones Sociales. Un contacto puede tener direccion propia o heredar la de su empresa.

## 5. Bloque BNI (campos personalizados)

HORIZONtic es franquicia regional de BNI (Business Network International). El 99% de los contactos son miembros BNI. Se necesita una pestana especifica en la ficha del contacto que muestre los datos BNI, visible solo cuando el contacto es miembro. Se implementa con un flag booleano y visibilidad condicional.

### 5.1 Campos personalizados en res.partner

| Campo Odoo | Etiqueta UI | Tipo | Descripcion |
|---|---|---|---|
| `x_studio_es_miembro_bni` | Es miembro BNI | Boolean | Flag que controla la visibilidad de la pestana "BNI". TRUE por defecto para los 2.011 contactos con datos BNI en la BBDD actual. |
| `x_studio_region_bni` | Region BNI | Many2one -> x_region_bni | Region geografica: AGI, BIB, NAV, etc. Catalogo cerrado. |
| `x_studio_grupo_bni` | Grupo / Capitulo | Many2one -> x_grupo_bni | Capitulo BNI. Ej. "BNI AGI Erronka". FK a Region. |
| `x_studio_estado_bni` | Estado BNI | Selection | activo / baja / pendiente / suspendido. Independiente del active general. |
| `x_studio_actividad_bni` | Actividad representada | Many2one -> x_actividad_bni | Gremio que el miembro representa (BNI admite solo un miembro por capitulo y actividad). |

### 5.2 Modelos auxiliares a crear

| Modelo | Campos | Volumen inicial |
|---|---|---|
| `x_region_bni` | name (Char) | 4 regiones (AGI, BIB, BIB Vit, NAV) |
| `x_grupo_bni` | name (Char), region_id (Many2one -> x_region_bni) | 37 capitulos activos |
| `x_actividad_bni` | name (Char), categoria (Char), descripcion (Text) | 512 especialidades BNI Connect 2026 |

*El catalogo de actividades incluye ya las 512 especialidades oficiales BNI Connect 2026 agrupadas en 27 categorias profesionales. El implantador puede importarlas directamente desde la plantilla.*

### 5.3 Configuracion de vista (form view)

En la vista de formulario de res.partner tipo person, anadir una pestana "BNI" con los cuatro campos (Region, Grupo, Estado, Actividad). Debe ser condicionalmente invisible segun el flag: `invisible="not x_studio_es_miembro_bni"`. Se puede hacer con Studio o mediante modulo XML custom.

## 6. Consideraciones sobre el nombre comercial

El campo x_studio_nombre_comercial es de alto uso en HORIZONtic. Las empresas suelen conocerse por su marca comercial mas que por su razon social (ej. "Moreno Abogados" se factura como MORENO ALBENDEA, IGNACIO). Requisitos:

- Campo Char **indexado** para busquedas rapidas.
- Aparece en la vista de formulario **debajo del campo name**.
- Aparece en la **vista lista** por defecto como columna visible.
- Entra en el **dominio de busqueda rapida** del buscador superior.
- Editable en **creacion rapida** (quick create) desde otros modulos.

## 7. Cuentas bancarias (res.partner.bank)

Modelo nativo, sin personalizacion. Cada partner puede tener varias cuentas.

| Campo Odoo | Etiqueta UI | Tipo | Descripcion |
|---|---|---|---|
| `id` | - | External ID | hzn.bank_NNNN. |
| `partner_id` | Titular | Many2one -> res.partner | External ID del partner. |
| `acc_number` | Numero de cuenta | Char | IBAN completo. Validacion automatica con l10n_es. |
| `bank_id` | Banco | Many2one -> res.bank | Entidad bancaria. Opcional. |
| `currency_id` | Moneda | Many2one -> res.currency | base.EUR por defecto. |
| `allow_out_payment` | Permite pagos salientes | Boolean | TRUE para pagos a proveedor. |
| `sequence` | Orden | Integer | Cuando hay varias cuentas. |

*En la migracion inicial esta tabla viaja vacia. Se ira poblando durante el ano previo para los partners que reciban transferencias.*

## 8. Modulos y localizacion requeridos

| Modulo | Necesidad | Motivo |
|---|---|---|
| `base` | Estandar | Core de res.partner. |
| `contacts` | Estandar | Vista y menu del modulo de Contactos. |
| `l10n_es` | Imprescindible | Localizacion espanola: PGC PYMES, validacion CIF/NIF, provincias. |
| `l10n_es_edi_facturae` | Recomendado | Facturacion electronica normativa espanola. |
| `l10n_es_edi_tbai` | Recomendado (PV) | TicketBAI para Bizkaia, Araba, Gipuzkoa. |
| `account` | Imprescindible | Contabilidad - subcuentas por partner. |
| `sale, purchase` | Imprescindible | Ventas y compras - customer/supplier_rank. |
| `studio` | Recomendado | Facilita crear campos y visibilidad condicional. Alternativa: modulo XML custom. |

## 9. Plan de importacion (por fases)

La plantilla Excel esta estructurada segun este plan. Cada hoja se exporta a CSV (UTF-8) y se importa en el modelo correspondiente.

### Paso 0 - Preparacion

1. Instalar los modulos listados en 8.
2. Crear los 6 campos personalizados y 3 modelos auxiliares (5).
3. Configurar la vista formulario de res.partner con la pestana BNI condicional.
4. Verificar que las subcuentas contables legacy existen.
5. Importar los catalogos: regiones, grupos, actividades BNI.

### Fase 1 - Razones sociales activas

Importar hoja "Razones sociales" filtrando active=TRUE. Resultado: 1.174 fichas res.partner.

### Fase 2 - Razones sociales archivadas

Importar las 33 fichas con active=FALSE. Conservan sus subcuentas contables originales. El campo x_studio_sucesor_id apunta a la razon social activa que las reemplaza.

### Fase 3 - Contactos personales

Importar hoja "Contactos". parent_id/id resuelve el vinculo con la razon social gracias al external ID. Los 2.011 contactos con x_studio_es_miembro_bni=TRUE mostraran la pestana BNI.

### Fase 4 - Cuentas bancarias

Importar hoja "Cuentas bancarias" (vacia inicialmente). Vinculo via partner_id/id.

## 10. Validaciones post-migracion

Al finalizar la carga, verificar:

- Conteo total: 3.232 registros res.partner (1.174 + 33 + 2.025).
- Las 41 fichas que actuan como cliente y proveedor tienen ambos rangs a 1 y ambas subcuentas.
- Los 33 archivados figuran solo con filtro "Archivados" y tienen sucesor asignado.
- Los 40 contactos originalmente vinculados a razones sociales obsoletas estan reasignados a la sucesora activa.
- Busquedas por nombre comercial, razon social y CIF retornan la misma ficha.
- Pestana BNI visible solo en los 2.011 contactos marcados; oculta en no-BNI y en razones sociales.
- Desplegables Region/Grupo/Actividad muestran catalogos correctos con filtrado en cascada.
- Ninguna ficha activa apunta a un partner archivado en parent_id.

## 11. Documentacion anexa entregada

| Documento | Contenido |
|---|---|
| `BBDD_HORIZONtic_Odoo.xlsx` | Plantilla Excel viva con datos precargados. 9 hojas: Inicio, 3 principales (Razones sociales, Contactos, Cuentas bancarias) y 5 auxiliares (Provincias, Municipios, Regiones BNI, Grupos BNI, Actividades BNI). Provincia y municipio son desplegables dependientes. |
| `Resumen_Campos_Plantilla_Odoo.pdf` | Resumen breve del contenido de la plantilla (5 paginas). |
| `Informe_Migracion_Odoo_v5.docx` | Informe detallado del analisis de calidad, depuracion y plan de carga. |
| `BBDD-HORIZONtic_ANALISIS_v5.xlsx` | Anexo con todos los hallazgos (duplicados, obsoletos, calidad de datos). |

*Este documento describe unicamente el modulo de Contactos. Otros modulos de Odoo (Ventas, Compras, Facturacion, TicketBAI, Analitica) seran objeto de especificacion aparte.*
