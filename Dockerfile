FROM --platform=linux/arm64 php:8.2-cli

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y \
        procps \
        nano \
        htop \
        git \
        wget \
        curl \
        openssl \
        libssl-dev \
        libpng-dev \
        libxml2-dev \
        libgmp-dev \
        libyaml-dev \
        libz-dev \
        g++ \
        iputils-ping \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libcurl4-gnutls-dev \
        libxpm-dev \
        libvpx-dev \
        libonig-dev \
        mediainfo

# Some basic extensions
RUN docker-php-ext-install -j$(nproc) mbstring opcache

# Install gd
RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/
RUN docker-php-ext-install gd

# Install mysql
RUN docker-php-ext-install -j$(nproc) pdo pdo_mysql mysqli

# Install pgsql
RUN apt-get install -y libpq-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo_pgsql pgsql

# Intl
RUN apt-get install -y libicu-dev
RUN docker-php-ext-install -j$(nproc) intl

# Install amqp
RUN apt-get install -y \
        librabbitmq-dev \
        libssh-dev \
    && docker-php-ext-install \
        bcmath \
        sockets

# Install Memcached
RUN apt-get install -y libmemcached-dev zlib1g-dev
RUN pecl install memcached
RUN docker-php-ext-enable memcached

# Install PECL Redis
RUN pecl install redis && docker-php-ext-enable redis

# Install APCu backward compatibility
RUN pecl install apcu && docker-php-ext-enable apcu --ini-name 10-docker-php-ext-apcu.ini

# Install mongodb
RUN apt-get install -y \
        libssl-dev \
    && pecl install mongodb \
    && docker-php-ext-enable mongodb

# Install zip
RUN apt-get install -y \
        libzip-dev \
        zip \
        unzip \
  && docker-php-ext-configure zip \
  && docker-php-ext-install zip

RUN docker-php-ext-install exif

# Install openswoole
RUN cd /tmp && git clone https://github.com/openswoole/ext-openswoole.git && \
    cd ext-openswoole && \
    git checkout v22.0.0 && \
    phpize  && \
    ./configure --enable-openssl --enable-hook-curl --enable-http2 --enable-mysqlnd && \
    make && make install
RUN echo 'extension=openswoole.so' > /usr/local/etc/php/conf.d/zzz_openswoole.ini

# Install xdebub
RUN pecl install xdebug

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- \
        --filename=composer \
        --install-dir=/usr/local/bin

# set up UTF-8 locale
RUN apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8

RUN apt-get clean && apt-get autoclean && apt-get autoremove -y
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN mkdir -p /var/log/php

RUN chown -R www-data:www-data /var/www

COPY ./conf.d/ /usr/local/etc/php/conf.d

ENV APP_ENV=prod
ENV SWOOLE_RUNTIME=1

COPY ./docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
