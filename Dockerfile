# Usar la imagen oficial de PHP 8.2 con Apache
FROM php:8.2-apache

# Instalar dependencias del sistema operativo
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libc-client-dev \
    libkrb5-dev \
    libicu-dev \
    unzip \
    curl \
    git \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Configurar e instalar extensiones PHP requeridas por SuiteCRM
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install gd mysqli pdo pdo_mysql zip soap intl imap opcache bcmath

# Habilitar mod_rewrite y headers de Apache
RUN a2enmod rewrite headers

# Descargar y extraer SuiteCRM 8.9 oficial directamente a /var/www/html
WORKDIR /var/www/html
RUN curl -o suitecrm.zip -L https://suitecrm.com/download/142/suite89/562972/suitecrm-8-9-2.zip \
    && unzip -q suitecrm.zip -d /var/www/html \
    && rm suitecrm.zip

# Cambiar el DocumentRoot de Apache a la carpeta /public (Requisito de SuiteCRM 8)
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Aplicar los permisos estrictos de directorios y archivos
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 2775 {} \; \
    && find /var/www/html -type f -exec chmod 0664 {} \; \
    && chmod +x /var/www/html/bin/console || true

# Crear un php.ini optimizado para el CRM
RUN echo "memory_limit=512M\nupload_max_filesize=60M\npost_max_size=60M\nmax_execution_time=120" > /usr/local/etc/php/conf.d/suitecrm.ini

EXPOSE 80