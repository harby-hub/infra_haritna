# ============================================
# Stage 1: Install Composer dependencies
# ============================================
FROM php:8.4-fpm-alpine AS deps

RUN apk add --no-cache \
    postgresql-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    libxml2-dev \
    oniguruma-dev \
    linux-headers \
    $PHPIZE_DEPS

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo_pgsql \
        pgsql \
        gd \
        intl \
        zip \
        bcmath \
        mbstring \
        xml \
        opcache \
        pcntl \
        exif

RUN pecl install redis && docker-php-ext-enable redis

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copy Laravel source from backend_dukkan/
COPY backend_dukkan/composer.json backend_dukkan/composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

COPY backend_dukkan/ .
RUN composer dump-autoload --optimize --no-dev

# ============================================
# Stage 2: Production image
# ============================================
FROM php:8.4-fpm-alpine AS production

RUN apk add --no-cache \
    postgresql-libs \
    libzip \
    libpng \
    libjpeg-turbo \
    freetype \
    icu-libs \
    libxml2 \
    oniguruma

# Copy compiled extensions from deps stage (no rebuild needed)
COPY --from=deps /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=deps /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Copy custom PHP and FPM config from infra repo
COPY infra_haritna/production/dukkan/backend/php.ini /usr/local/etc/php/conf.d/99-custom.ini
COPY infra_haritna/production/dukkan/backend/www.conf /usr/local/etc/php-fpm.d/www.conf

WORKDIR /var/www

# Copy application with dependencies from deps stage
COPY --from=deps /var/www /var/www

# Copy Passport keys
COPY infra_haritna/production/dukkan/keys/oauth-private.key /var/www/storage/oauth-private.key
COPY infra_haritna/production/dukkan/keys/oauth-public.key /var/www/storage/oauth-public.key

# Create required directories and set permissions
RUN mkdir -p storage/framework/{cache,sessions,testing,views} \
    && mkdir -p storage/logs \
    && mkdir -p bootstrap/cache \
    && chmod 600 storage/oauth-private.key storage/oauth-public.key \
    && chown -R www-data:www-data storage bootstrap/cache

USER www-data

EXPOSE 9000

CMD ["php-fpm"]
