FROM alpine AS dependencies

ENV TTRSS_URL https://git.tt-rss.org/git/tt-rss/archive/master.tar.gz

ADD ${TTRSS_URL} /ttrss.tar.gz

RUN set -xe \
	&& apk add --no-cache tar \
	&& mkdir -p /dependencies/ttrss \
	&& tar -xf /ttrss.tar.gz --strip-components=1 -C /dependencies/ttrss

FROM php:apache

VOLUME /volume/configuration /volume/plugins /volume/themes

ENV APACHE_PORT=8080 \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_DOCUMENT_ROOT=/var/www/html

# This is not strictly necessary, but makes it easier for users to expose all
# ports automatically.
EXPOSE ${APACHE_PORT}

WORKDIR ${APACHE_DOCUMENT_ROOT}

COPY --from=dependencies /dependencies/ttrss ${APACHE_DOCUMENT_ROOT}

# To enable logging for a non-root user, the user has to be added to the tty
# group as described in [0]. Additionally, the default log files are explicitly
# set to stdout and stderr.
# [0] https://github.com/moby/moby/issues/31243#issuecomment-406879017
RUN set -ex \
	&& usermod -a -G tty ${APACHE_RUN_USER} \
	&& sed -i "s/Listen 80/Listen ${APACHE_PORT}/g" /etc/apache2/ports.conf \
	&& sed -i "s/:80>/:${APACHE_PORT}>/g" /etc/apache2/sites-available/000-default.conf \
	&& sed -i 's!ErrorLog.*!ErrorLog /dev/stderr!g' /etc/apache2/*.conf /etc/apache2/sites-available/*.conf \
	&& sed -i 's!CustomLog.*!CustomLog /dev/stdout common!g' /etc/apache2/*.conf /etc/apache2/sites-available/*.conf \
	&& find . -type f -print0 | xargs -0 chmod 0640 \
	&& find . -type d -print0 | xargs -0 chmod 0750 \
	&& chown -R root:${APACHE_RUN_USER} ./ \
	&& chown ${APACHE_RUN_USER}:${APACHE_RUN_USER} ./ \
	&& chown -R ${APACHE_RUN_USER}:${APACHE_RUN_USER} ./cache/ \
	&& chown -R ${APACHE_RUN_USER}:${APACHE_RUN_USER} ./feed-icons/ \
	&& chown -R ${APACHE_RUN_USER}:${APACHE_RUN_USER} ./lock/ \
	&& mkdir -p /volume/configuration \
	&& chown ${APACHE_RUN_USER}:${APACHE_RUN_USER} /volume/configuration \
	&& chmod 750 /volume/configuration \
	&& ln -s -f /volume/configuration/config.php ./config.php \
	&& mkdir -p /volume/plugins \
	&& chown root:${APACHE_RUN_USER} /volume/plugins \
	&& chmod 750 /volume/plugins \
	&& rm -rf ./plugins.local \
	&& ln -s /volume/plugins ./plugins.local \
	&& mkdir -p /volume/themes \
	&& chown root:${APACHE_RUN_USER} /volume/themes \
	&& chmod 750 /volume/themes \
	&& rm -rf ./themes.local \
	&& ln -s /volume/themes ./themes.local \
	&& { \
		echo 'opcache.enable=1'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=10000'; \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.save_comments=1'; \
		echo 'opcache.revalidate_freq=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini \
	&& echo 'memory_limit=512M' > /usr/local/etc/php/conf.d/memory-limit.ini \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		libxml2-dev \
		zlib1g-dev \
		libpng-dev \
		libjpeg-dev \
		libonig-dev \
		libzip-dev \
	&& rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-install -j "$(nproc)" \
		dom \
		fileinfo \
		gd \
		intl \
		json \
		mbstring \
		mysqli \
		opcache \
		pcntl \
		pdo_mysql \
		posix \
		session \
		xml \
		zip

# Set a custom entrypoint.
COPY entrypoint.sh /entrypoint.sh
RUN chmod 540 /entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
