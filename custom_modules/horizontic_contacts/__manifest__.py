{
    "name": "HORIZONtic - Contactos",
    "summary": "Bloque BNI, razon social sucesora y ajustes del nombre comercial",
    "version": "19.0.1.0.0",
    "category": "Sales/CRM",
    "author": "La Kolmena",
    "license": "LGPL-3",
    "depends": ["contacts", "l10n_es_partner"],
    "data": [
        "security/ir.model.access.csv",
        "views/bni_views.xml",
        "views/res_partner_views.xml",
        "views/menus.xml",
    ],
    "installable": True,
    "application": False,
}
