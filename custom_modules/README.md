# Custom Modules

Coloca aquí tus módulos personalizados de Odoo. Cada módulo debe estar en su
propio subdirectorio con su `__manifest__.py`.

```
custom_modules/
├── mi_modulo/
│   ├── __init__.py
│   ├── __manifest__.py
│   ├── models/
│   └── views/
└── otro_modulo/
    └── ...
```

Este directorio se monta dentro del contenedor en `/mnt/custom-addons` y está
incluido en `addons_path` antes que enterprise, community y extra-addons, por
lo que tus módulos pueden sobrescribir comportamiento de cualquier otro módulo
si lo necesitas.

Tras añadir un módulo nuevo, en Odoo:

1. Activa el modo desarrollador
2. Ve a **Aplicaciones → Actualizar lista de aplicaciones**
3. Busca tu módulo e instálalo
