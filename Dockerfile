FROM php:8.2-apache-bookworm

RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev \
    libxml2-dev libc-client-dev libkrb5-dev libicu-dev \
    unzip curl git cron && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install gd mysqli pdo pdo_mysql zip soap intl imap opcache bcmath

RUN a2enmod rewrite headers
WORKDIR /var/www/html

RUN curl -o suitecrm.zip -L https://suitecrm.com/download/142/suite89/562972/suitecrm-8-9-2.zip \
    && unzip -q suitecrm.zip -d /var/www/html \
    && rm suitecrm.zip

# CREACIÓN DE CARPETAS CRÍTICAS Y PERMISOS ANTES DEL DEPLOY
RUN mkdir -p var/cache var/logs var/sessions public/legacy/cache \
    && chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 2775 {} \; \
    && find /var/www/html -type f -exec chmod 0664 {} \; \
    && chmod +x bin/console

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

# CONFIGURACIÓN DE SESIONES PHP PARA EVITAR EL REBOTE DE LOGIN
RUN echo "session.save_path = \"/var/www/html/var/sessions\"\nmemory_limit=512M\nerror_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT\ndisplay_errors = Off" > /usr/local/etc/php/conf.d/suitecrm.ini

EXPOSE 80
