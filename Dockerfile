FROM php:8.2-apache-bookworm

# Instalar dependencias
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev \
    libxml2-dev libc-client-dev libkrb5-dev libicu-dev \
    unzip curl git cron && rm -rf /var/lib/apt/lists/*

# Instalar extensiones PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install gd mysqli pdo pdo_mysql zip soap intl imap opcache bcmath

RUN a2enmod rewrite headers
WORKDIR /var/www/html

# Descargar y descomprimir SuiteCRM 8.9.2
RUN curl -o suitecrm.zip -L https://suitecrm.com/download/142/suite89/562972/suitecrm-8-9-2.zip \
    && unzip -q suitecrm.zip -d /var/www/html \
    && rm suitecrm.zip

# Pre-crear carpetas críticas para evitar Error 500
RUN mkdir -p var/cache var/logs public/legacy/cache

# Configurar Apache DocumentRoot y AllowOverride
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

# Aplicar permisos (Corregido con \;)
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 2775 {} \; \
    && find /var/www/html -type f -exec chmod 0664 {} \; \
    && chmod +x /var/www/html/bin/console || true

# Optimizar PHP (Ocultar advertencias que rompen el instalador)
RUN echo "memory_limit=512M\nupload_max_filesize=60M\npost_max_size=60M\nmax_execution_time=120\nerror_reporting=E_ALL & ~E_DEPRECATED & ~E_STRICT\ndisplay_errors=Off" > /usr/local/etc/php/conf.d/suitecrm.ini

EXPOSE 80
