FROM nginx:mainline

# install utilities
RUN apt update && apt install -y unzip git supervisor cron nano

# install nodejs
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
RUN apt install -y nodejs

# prepare nginx for rootless mode
COPY includes/config/fastcgi.conf /etc/nginx/fastcgi.conf
RUN rm -rf /etc/nginx/fastcgi_params /usr/share/nginx/html/*
RUN chown -R nginx:nginx /var/cache/nginx /usr/share/nginx/html /etc/nginx \
    && chmod -R g+w /var/cache/nginx /etc/nginx

# install php
RUN curl -sSL https://packages.sury.org/php/README.txt | bash -x
RUN apt install -y php8.4 php8.4-fpm php8.4-curl php8.4-dom php8.4-fileinfo php8.4-gd php8.4-iconv php8.4-intl php8.4-cli php8.4-mbstring php8.4-pdo php8.4-pdo-mysql php8.4-phar php8.4-simplexml php8.4-xml php8.4-zip php8.4-zstd php8.4-redis

# configure php-fpm
RUN sed -e 's/run\/php/tmp/' -i /etc/php/8.4/fpm/php-fpm.conf
COPY includes/config/www-pool.conf /etc/php/8.4/fpm/pool.d/www.conf
COPY includes/config/php.ini /etc/php/8.4/fpm/php.ini
RUN touch /var/log/php8.4-fpm.log
RUN chown -R nginx:nginx /var/log/php8.4-fpm.log /etc/php/8.4/fpm

# install composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer

# set up cron job for scheduled tasks
COPY includes/cronjobs /etc/cron.d/sw-cronjobs
RUN chmod 0644 /etc/cron.d/sw-cronjobs \
    && crontab /etc/cron.d/sw-cronjobs \
    && touch /var/log/sw-cronjobs.log \
    && chown www-data:www-data /var/log/sw-cronjobs.log

# set up supervisor
COPY includes/config/supervisord.conf /etc/supervisor/supervisord.conf
RUN touch /var/log/supervisord.log && chown nginx:nginx /var/log/supervisord.log

# create entrypoint directory
RUN rm -rf /docker-entrypoint.d
RUN mkdir -p /docker-entrypoint.d && chown -R nginx:nginx /docker-entrypoint.d

# copy Shopware files
USER nginx
WORKDIR /usr/share/nginx/html
RUN mkdir -p public
COPY --chown=nginx:nginx --chmod=0777 sw-symfony-flex .

# copy nginx configuration
USER root
COPY includes/config/nginx.conf /etc/nginx/nginx.conf
RUN usermod -d /usr/share/nginx nginx \
    && chown nginx:nginx /usr/share/nginx \
    && chmod 0777 /usr/share/nginx

# add entrypoint scripts
COPY includes/scripts/entrypoint.sh /entrypoint.sh
RUN echo "#!/bin/sh\ncd /usr/share/nginx/html\nphp bin/console messenger:setup-transports\nphp bin/console dal:refresh:index --use-queue\n" > /docker-entrypoint.d/10-index-shopware.sh
RUN chmod +x /entrypoint.sh /docker-entrypoint.d/*.sh

CMD ["sh", "/entrypoint.sh"]