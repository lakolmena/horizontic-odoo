from odoo import fields, models


class BniRegion(models.Model):
    _name = "bni.region"
    _description = "Region BNI"
    _order = "name"

    name = fields.Char(string="Region", required=True)
    active = fields.Boolean(default=True)
    grupo_ids = fields.One2many("bni.grupo", "region_id", string="Grupos / Capitulos")

    _name_uniq = models.Constraint("unique(name)", "Ya existe una region BNI con ese nombre.")


class BniGrupo(models.Model):
    _name = "bni.grupo"
    _description = "Grupo / Capitulo BNI"
    _order = "region_id, name"

    name = fields.Char(string="Grupo / Capitulo", required=True)
    region_id = fields.Many2one("bni.region", string="Region", required=True, ondelete="restrict")
    active = fields.Boolean(default=True)

    _name_uniq = models.Constraint("unique(name)", "Ya existe un grupo BNI con ese nombre.")


class BniActividad(models.Model):
    _name = "bni.actividad"
    _description = "Actividad BNI"
    _order = "categoria, name"

    name = fields.Char(string="Actividad", required=True)
    categoria = fields.Char(string="Categoria", index=True)
    descripcion = fields.Text(string="Descripcion")
    active = fields.Boolean(default=True)

    _name_categoria_uniq = models.Constraint(
        "unique(name, categoria)", "Ya existe esa actividad BNI en la categoria."
    )
