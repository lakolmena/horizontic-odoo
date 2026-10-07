from odoo import _, api, fields, models
from odoo.exceptions import ValidationError


class ResPartner(models.Model):
    _inherit = "res.partner"

    sucesor_id = fields.Many2one(
        "res.partner",
        string="Sucesora",
        domain="[('is_company', '=', True), ('id', '!=', id)]",
        ondelete="restrict",
        help="Razon social activa que reemplaza a esta ficha archivada.",
    )

    bni_es_miembro = fields.Boolean(string="Es miembro BNI", index=True)
    bni_grupo_id = fields.Many2one("bni.grupo", string="Grupo / Capitulo", ondelete="restrict")
    bni_region_id = fields.Many2one(
        "bni.region",
        string="Region BNI",
        compute="_compute_bni_region_id",
        store=True,
        readonly=False,
        ondelete="restrict",
    )
    bni_estado = fields.Selection(
        [
            ("activo", "Activo"),
            ("baja", "Baja"),
            ("pendiente", "Pendiente"),
            ("suspendido", "Suspendido"),
        ],
        string="Estado BNI",
    )
    bni_actividad_id = fields.Many2one(
        "bni.actividad", string="Actividad representada", ondelete="restrict"
    )

    @api.depends("bni_grupo_id")
    def _compute_bni_region_id(self):
        for partner in self.filtered("bni_grupo_id"):
            partner.bni_region_id = partner.bni_grupo_id.region_id

    @api.constrains("bni_region_id", "bni_grupo_id")
    def _check_bni_grupo_region(self):
        for partner in self:
            grupo = partner.bni_grupo_id
            if grupo and grupo.region_id != partner.bni_region_id:
                raise ValidationError(
                    _(
                        "%(contacto)s: el grupo BNI %(grupo)s pertenece a la region "
                        "%(region)s, no a %(otra)s.",
                        contacto=partner.display_name,
                        grupo=grupo.name,
                        region=grupo.region_id.name,
                        otra=partner.bni_region_id.name or "-",
                    )
                )

    @api.onchange("bni_region_id")
    def _onchange_bni_region_id(self):
        if self.bni_grupo_id and self.bni_grupo_id.region_id != self.bni_region_id:
            self.bni_grupo_id = False
