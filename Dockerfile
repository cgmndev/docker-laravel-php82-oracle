FROM ubuntu:22.04

LABEL maintainer="claudio.mnec@gmail.com"

ARG WWWGROUP
ARG NODE_VERSION=18
ARG POSTGRES_VERSION=15

WORKDIR /var/www/html

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
    && apt-get install -y gosu curl ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev python2 software-properties-common libaio1 libaio-dev openssl iputils-ping  make rlwrap tar glibc-source \
    && add-apt-repository ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y php8.2-cli \
      php8.2 \
      php8.2-pgsql \
      php8.2-sqlite3 \
      php8.2-gd \
      php8.2-curl \
      php8.2-imap \
      php8.2-mysql \
      php8.2-mbstring \
      php8.2-xml \
      php8.2-zip \
      php8.2-bcmath \
      php8.2-soap \
      php8.2-intl \
      php8.2-readline \
      php8.2-ldap \
      php8.2-msgpack \
      php8.2-igbinary \
      php8.2-redis \
      php8.2-swoole \
      php8.2-memcached \
      php8.2-pcov \
      php8.2-xdebug \
      php8.2-dev \
    && php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer \
    && curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/keyrings/pgdg.gpg >/dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt jammy-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y yarn \
    && apt-get install -y mysql-client \
    && apt-get install -y postgresql-client-$POSTGRES_VERSION \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN setcap "cap_net_bind_service=+ep" /usr/bin/php8.2

RUN useradd -ms /bin/bash -u 1000 laraveluser


RUN	mkdir /opt/oracle
COPY 	./oracle-client /opt/oracle

RUN	cd /opt/oracle/ && \
	unzip instantclient-basic-linux.x64-21.10.0.0.0dbru.zip && \
	unzip instantclient-sqlplus-linux.x64-21.10.0.0.0dbru.zip && \
	unzip instantclient-sdk-linux.x64-21.10.0.0.0dbru.zip && \
	echo "/opt/oracle/instantclient_21_10/" >> /etc/ld.so.conf.d/oracle-instantclient.conf && \
	ldconfig && \
	echo 'export ORACLE_HOME=/opt/oracle' >> ~/.bashrc && \
	echo 'PATH=$PATH:/opt/oracle/instantclient_21_10' >> ~/.bashrc && \
	echo "alias sqlplus='/usr/bin/rlwrap -m /opt/oracle/instantclient_21_10/sqlplus'" >> ~/.bashrc && \
	cd /opt/oracle && \
	pecl download oci8-3.3.0 && \
	tar -xzvf oci8*.tgz && \
	cd oci8-3.3.0 && \
	phpize && \
	./configure --with-oci8=instantclient,/opt/oracle/instantclient_21_10/ && \
	make install && \
	echo 'instantclient,/opt/oracle/instantclient_21_10' | pecl install oci8


COPY start-container /usr/local/bin/start-container
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini /etc/php/8.2/cli/conf.d/99-custom-php.ini
RUN chmod +x /usr/local/bin/start-container

EXPOSE 8000

ENTRYPOINT ["start-container"]
