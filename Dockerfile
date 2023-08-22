# Docker Image for the new backend.
# When changing anything in this file, don't forget to re-build the image and push the changes
# to dockerhub:
#
# docker build -t hozanaci/backend:latest .
# docker push hozanaci/backend:latest
#
FROM php:8.1-fpm
LABEL org.opencontainers.image.authors="marco@hozana.org"

# nvm environment variables
ENV NODE_VERSION 16.18.0
ENV NVM_DIR /usr/local/nvm

# Add necesary libraries
RUN apt-get update \
    && apt-get upgrade -y --allow-unauthenticated \
    && apt-get install -y --allow-unauthenticated \
        apt-transport-https \
        libfcgi0ldbl \
        curl \
        git \
        libpcre3-dev \
        net-tools \
        rsyslog \
        zlib1g-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libgmp-dev \
        libexif-dev \
        libzip-dev \
        zip \
        unzip \
        gnupg \
        libicu-dev \
        ghostscript \
        build-essential \
        libssl-dev \
        libonig-dev \
        librabbitmq-dev \
        libxml2-dev libxslt-dev \
        locales \
    && docker-php-ext-configure gd \
    && docker-php-ext-configure gmp \
    && docker-php-ext-configure intl

# Add PHP extensions
RUN docker-php-ext-install \
    mbstring \
    pdo \
    pdo_mysql \
    zip \
    gd \
    exif \
    gmp \
    intl \
    opcache \
    xsl \
    pcntl

RUN mkdir -p $NVM_DIR && curl -s -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

# install node and npm
RUN . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# install yarn
RUN npm install -g yarn

# configure english utf8 locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# add PECL extensions
RUN pecl install xdebug && docker-php-ext-enable xdebug && \
    pecl install redis && docker-php-ext-enable redis && \
    pecl install amqp && docker-php-ext-enable amqp && \
    pecl install apcu && docker-php-ext-enable apcu

# Configure PHP
COPY usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf 
COPY usr/local/etc/php/conf.d/php.ini /usr/local/etc/php/conf.d/php.ini

# Configure Apache for API, admin, CRM
#COPY ./tools/docker/backend/hozana-dev.conf /etc/apache2/sites-available/hozana.conf
#RUN a2ensite hozana

# remove default site, not serving anything anyway
#RUN a2dissite 000-default
# enable necesary Apache modules
#RUN a2enmod \
#    deflate \
#    rewrite \
#    headers \
#    proxy \
#    proxy_connect \
#    proxy_http \
#    proxy_wstunnel \
#    ssl

#Configure supervisord and syslog
#RUN mkdir -p /var/log/supervisor /data/code
#COPY ./tools/docker/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
#COPY ./tools/docker/rsyslog/rsyslog.conf /etc/rsyslog.conf

RUN mkdir -p /data/code
WORKDIR /data/code

# Copy codebase to deploy images fully tested
COPY ./backend /data/code

# Install Composer and make its cache directory world-writable
# as we will later run it under a local user id.
#COPY ./tools/docker/scripts/install_composer.sh /data/scripts/


COPY usr/local/sbin/install_composer.sh /usr/local/sbin/install_composer.sh 
COPY usr/local/bin/docker-php-entrypoint /usr/local/bin/docker-php-entrypoint

RUN /usr/local/sbin/install_composer.sh \
 && mkdir -p /.composer && chmod -R 777 /.composer \
 && cd /data/code \
 && HOZANA_DB_URL=sqlite:///:memory: \
 && HOZANA_DB_E2E_URL=sqlite:///:memory: \
 && HOZANA_CRM_DB_URL=sqlite:///:memory: \
 && COMPOSER_ALLOW_SUPERUSER=1 composer install --prefer-dist --no-progress --no-interaction \
 && yarn install 

# Docker entrypoint
#COPY ./tools/docker/scripts/docker-entrypoint.sh /data/scripts/
#ENTRYPOINT ["/data/scripts/docker-entrypoint.sh"]

VOLUME ["/data/code"]

#COPY ./tools/docker/backend/entrypoint.sh /usr/local/bin/

RUN docker-php-source delete && \
    rm -r /tmp/* /var/cache/*

CMD php-fpm
ENTRYPOINT ["/usr/local/bin/docker-php-entrypoint"]
HEALTHCHECK --interval=15s \
    --timeout=30s \
    --start-period=30s \
    --retries=10 \
    CMD SCRIPT_FILENAME=/data/code/public/index.php \
        SCRIPT_NAME=/api/fr/server-info \
        REQUEST_URI=/api/fr/server-info \
        QUERY_STRING= \
        REQUEST_METHOD=GET \
        SERVER_NAME=hozana.local \
        SERVER_PORT=443 \
        HTTPS=true \
        cgi-fcgi -bind -connect localhost:9000 || exit 1