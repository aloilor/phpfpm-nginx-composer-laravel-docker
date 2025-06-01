################################################################
#  Laravel + Statamic · Nginx · PHP-FPM 8.3 · CloudWatch logs  #
################################################################
FROM php:8.3-fpm-alpine 

# ---------- 1. System packages & PHP extensions ----------
RUN apk add --no-cache \
        nginx supervisor git curl zip unzip icu-libs oniguruma libpng \
        icu-dev oniguruma-dev libpng-dev autoconf make g++ \
    && docker-php-ext-install -j$(nproc) \
        bcmath      \  
        exif        \ 
        gd          \ 
        intl        \ 
        mbstring    \ 
        pdo_mysql   \ 
        opcache     \
    && apk del --no-network icu-dev oniguruma-dev libpng-dev autoconf make g++

# ---------- 2. Composer ----------
RUN curl -sS https://getcomposer.org/installer \
    | php -- --install-dir=/usr/local/bin --filename=composer

# ---------- 3. Application code --------------------------------------------
WORKDIR /var/www/html
COPY . .

# ── 3.1  Install PHP dependencies as root ───────────────────────────────────
RUN composer install --no-dev --prefer-dist --optimize-autoloader

# ── 3.2  Pre-warm Statamic/Laravel caches (still as root) ───────────────────
RUN php artisan optimize:clear          \
    && php please stache:refresh  || true  \
    && php please static:clear    || true

# ── 3.3  Ensure every writable directory exists and is accessible to FPM ────
RUN set -eux; \
    mkdir -p \
        storage/framework/{cache,data,sessions,testing,views} \
        storage/logs \
        bootstrap/cache; \
    chown -R www-data:www-data \
        storage  bootstrap/cache; \
    chmod -R ug+rwX \
        storage  bootstrap/cache


# ---------- 4. CloudWatch-friendly logging with awslogs drive----------
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log \
 && { \
 echo "error_log = /proc/self/fd/2"; \
 echo "log_errors = On";            \   
 echo "display_errors = Off";       \ 
} > /usr/local/etc/php/conf.d/error_log.ini


RUN { \
 echo '[global]'; \
 echo 'error_log = /proc/self/fd/2'; \
 echo 'log_level = notice'; \
 echo ''; \
 echo '[www]'; \
 echo 'catch_workers_output = yes'; \
} > /usr/local/etc/php-fpm.d/zz-log.conf


# ---------- 5. Configuration & health check ----------
COPY docker/nginx.conf       /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisord.conf

EXPOSE 8080
HEALTHCHECK --interval=90s --timeout=3s CMD \
  wget -qO- http://127.0.0.1:8080/healthz || exit 1

CMD ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]
