FROM php:7.2.1-apache
MAINTAINER snp-technologies

COPY apache2.conf /bin/
COPY init_container.sh /bin/

RUN a2enmod rewrite expires include deflate

# install the PHP extensions we need
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         libpng-dev \
         libjpeg-dev \
         libpq-dev \
         libmcrypt-dev \
         libldap2-dev \
         libldb-dev \
         libicu-dev \
         libgmp-dev \
         libmagickwand-dev \
         openssh-server \
                 curl \
                 git \
                 mysql-client \
                 nano \
                 sudo \
                 tcptraceroute \
                 vim \
                 wget \
    && chmod 755 /bin/init_container.sh \
    && echo "root:Docker!" | chpasswd \
    && echo "cd /home" >> /etc/bash.bashrc \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
    && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h \
    && rm -rf /var/lib/apt/lists/* \
    && pecl install imagick-beta \
    && pecl install mcrypt-1.0.1 \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install \
         bcmath \
         bz2 \
         calendar \
         exif \
         gd \
         gmp \
         intl \
         ldap \
         mbstring \
         mysqli \
         opcache \
         pcntl \
         pdo \
         pdo_mysql \
         pdo_pgsql \
         pgsql \         
         soap \
         sockets \
         xmlrpc \
         zip \
    && docker-php-ext-enable imagick \
    && docker-php-ext-enable mcrypt
    
### Change apache logs directory ###
RUN   \
   rm -f /var/log/apache2/* \
   && rmdir /var/lock/apache2 \
   && rmdir /var/run/apache2 \
   && rmdir /var/log/apache2 \
   && chmod 777 /var/log \
   && chmod 777 /var/run \
   && chmod 777 /var/lock \
   && chmod 777 /bin/init_container.sh \
   && cp /bin/apache2.conf /etc/apache2/apache2.conf \
   && rm -rf /var/log/apache2 \
   && mkdir -p /home/LogFiles \
   && ln -s /home/LogFiles /var/log/apache2 

### Remove configuration files of the base image ###
RUN rm -rf /etc/apache2/sites-enabled/* \
   && rm -rf /etc/apache2/conf-enabled/*

RUN { \
                echo 'opcache.memory_consumption=128'; \
                echo 'opcache.interned_strings_buffer=8'; \
                echo 'opcache.max_accelerated_files=4000'; \
                echo 'opcache.revalidate_freq=60'; \
                echo 'opcache.fast_shutdown=1'; \
                echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN { \
  echo 'error_log=/var/log/apache2/php-error.log'; \
  echo 'log_errors=On'; \
  echo 'display_startup_errors=Off'; \
  echo 'date.timezone=UTC'; \
  echo 'session.cache_limiter = nocache'; \
  echo 'session.auto_start = 0'; \
  echo 'expose_php = off'; \
  echo 'allow_url_fopen = off'; \
  echo 'magic_quotes_gpc = off'; \
  echo 'register_globals = off'; \
  echo 'display_errors=Off'; \
  } > /usr/local/etc/php/conf.d/php.ini

COPY sshd_config /etc/ssh/

EXPOSE 2222 8080

ENV APACHE_RUN_USER www-data
ENV PHP_VERSION 7.2.1

ENV PORT 8080
ENV WEBSITE_ROLE_INSTANCE_ID localRoleInstance
ENV WEBSITE_INSTANCE_ID localInstance
ENV PATH ${PATH}:/var/www/html/

WORKDIR /var/www/html
## Put your code in the image, for example with git clone... ###
RUN git clone -b master [REPLACE WITH YOUR GIT REPOSITORY CLONE URL] .

# Add directories typically not included in the git repository
# These are mounted from /home

RUN mkdir -p  /home/site/wwwroot/wp-content/uploads/ \
    && ln -s /home/site/wwwroot/wp-content/uploads  /var/www/html/docroot/wp-content/uploads \
    && mkdir -p  /home/site/wwwroot/wp-content/backup-db/ \
    && ln -s /home/site/wwwroot/wp-content/backup-db  /var/www/html/docroot/wp-content/backup-db \
    && mkdir -p  /home/site/wwwroot/wp-content/backups/ \
    && ln -s /home/site/wwwroot/wp-content/backups  /var/www/html/docroot/wp-content/backups \
    && mkdir -p  /home/site/wwwroot/wp-content/blogs.dir/ \
    && ln -s /home/site/wwwroot/wp-content/blogs.dir  /var/www/html/docroot/wp-content/blogs.dir \
    && mkdir -p  /home/site/wwwroot/wp-content/cache/ \
    && ln -s /home/site/wwwroot/wp-content/cache  /var/www/html/docroot/wp-content/cache \    
    && mkdir -p  /home/site/wwwroot/wp-content/upgrade/ \
    && ln -s /home/site/wwwroot/wp-content/upgrade  /var/www/html/docroot/wp-content/upgrade
    
WORKDIR /var/www/html/docroot
RUN chown -R root:www-data .
RUN find . -type d -exec chmod u=rwx,g=rx,o= '{}' \;
RUN find . -type f -exec chmod u=rw,g=r,o= '{}' \;

ENTRYPOINT ["/bin/init_container.sh"]
