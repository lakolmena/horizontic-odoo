ARG ODOO_VERSION=18
FROM odoo:${ODOO_VERSION}

USER root

# Instalar dependencias adicionales que puedan requerir los módulos Enterprise
RUN apt-get update && apt-get install -y \
    python3-dev \
    libxml2-dev \
    libxslt1-dev \
    libsasl2-dev \
    libldap2-dev \
    libssl-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libopenjp2-7-dev \
    libfreetype6-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# Crear directorios para addons
RUN mkdir -p /mnt/enterprise-addons /mnt/community-addons

# Cambiar propietario de los directorios
RUN chown -R odoo:odoo /mnt/enterprise-addons /mnt/community-addons

# Instala dependencias Python adicionales para módulos OCA / custom.
# Edita requirements.txt para añadir más libs sin tocar el Dockerfile.
COPY requirements.txt /tmp/requirements.txt
RUN pip install --break-system-packages --no-cache-dir -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

USER odoo