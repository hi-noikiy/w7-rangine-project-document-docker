FROM alpine:3.8
MAINTAINER yuanwentao <admin@w7.cc>

# define variable
ENV add_user www
ENV TIMEZONE ${timezone:-"Asia/Shanghai"}
ENV SWOOLE_VERSION 4.4.4
ENV XHPROF_VERSION 2.1.0

# install init
RUN set -ex \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/' /etc/apk/repositories \
    && apk update \
    && apk upgrade \
    && apk add --no-cache \
    
    # Install base packages ('ca-certificates' will install 'nghttp2-libs')
    ca-certificates \
    
    git \
    curl \
    tar \
    xz \
    zip \
    unzip \
    libressl \
    # openssh  \
    # openssl  \
    tzdata \
    pcre \
    
    # ¼æÈÝÌÚÑ¶ÔÆÈÝÆ÷¹ÜÀí
    bash \
    bash-doc \
    bash-completion \
    && cd /bin && rm -f sh && ln -s /bin/bash sh
    
# install php7 and some extensions
RUN set -ex \
    && apk add --no-cache \
    php7 \
    # php7-common \
    php7-bcmath \
    php7-curl \
    php7-ctype \
    php7-dom \
    php7-fileinfo \
    # php7-gettext \
    php7-gd \
    php7-iconv \
    # php7-imagick \
    php7-json \
    php7-mbstring \
    php7-mongodb \
    php7-mysqlnd \
    php7-mysqli \
    php7-openssl \
    php7-mcrypt \
    php7-opcache \
    php7-pdo \
    php7-pdo_mysql \
    php7-pdo_sqlite \
    php7-phar \
    php7-posix \
    php7-redis \
    php7-memcached \
    php7-apcu \
    php7-simplexml \
    php7-xml \
    php7-xmlreader \
    php7-xmlrpc \
    php7-xmlwriter \
    php7-xsl \
    php7-sockets \
    php7-sodium \
    # php7-sqlite \
    php7-session \
    php7-sysvshm \
    php7-sysvmsg \
    php7-sysvsem \
    php7-tokenizer \
    php7-zip \
    php7-zlib \
    && apk del --purge *-dev \
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man /usr/share/php7 \
    
    # config PHP
    && mkdir -p /usr/local/etc/  \
    && chmod -R 755 /usr/local/etc \
    && mkdir /usr/tmp \
    && chmod -R 755 /usr/tmp \
    && echo "upload_max_filesize=500M\npost_max_size=500M\nmemory_limit=2048M\nsession.save_path=\"/usr/tmp\"\ndate.timezone=Asia/Shanghai" > /usr/local/etc/php.ini  \
    && ln -s /usr/local/etc/php.ini /etc/php7/conf.d/99-overrides.ini \
    
    # config timezone
    && ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    
    # config work
    && addgroup -g 1000 -S ${add_user} \
    && adduser -u 1000 -D -S -G ${add_user} ${add_user} \
    && rm -rf /home/${add_user} \
    
    # install latest composer
    && wget https://mirrors.aliyun.com/composer/composer.phar \
    && mv composer.phar /usr/local/bin/composer \
    && chmod 755 /usr/local/bin/composer \
    && composer config -g repos.packagist composer https://mirrors.cloud.tencent.com/composer/ \
    && echo -e "\033[42;37m Intasll PHP7 Completed :).\033[0m\n"

# install php7 swoole
ENV PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make php7-dev php7-pear pkgconf re2c pcre-dev zlib-dev"
RUN set -ex \
    && apk update \
    # libs for swoole extension. libaio linux-headers
    && apk add --no-cache libstdc++ openssl \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS libaio-dev openssl-dev \
    # php extension: swoole
    && cd /tmp \
    && curl -SL "https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz" -o swoole.tar.gz \
    && mkdir -p swoole \
    && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
    && rm swoole.tar.gz \
    && ( \
        cd swoole \
        && phpize \
        && ./configure --enable-sockets --enable-mysqlnd --enable-openssl \
        && make -j$(nproc) && make install \
    ) \
    && rm -r swoole \
    && echo "extension=swoole.so" > /etc/php7/conf.d/20_swoole.ini \
    && php -v \
    
    
    # ---------- clear works ----------
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man \
    && echo -e "\033[42;37m Install Swoole Completed :).\033[0m\n"


# add rangine
ADD . /home

EXPOSE 80
 