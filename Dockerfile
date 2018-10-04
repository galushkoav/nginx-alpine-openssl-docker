FROM alpine:3.7
LABEL maintainer "a.v.galushko86@gmail.com"

ENV COMPILE_DIR /build
ENV NB_PROC 4
ARG NGINX_VERSION
ENV VERSION_NGINX nginx-$NGINX_VERSION
ENV SOURCE_NGINX http://nginx.org/download/


RUN deluser xfs \
    && addgroup -g 33 -S www-data \
    && adduser -u 33 -D -S -G www-data www-data \
    && apk add --no-cache \
     ca-certificates \
     openldap-dev \
     pcre \
     zlib \
     libgcc \
     openssl \
     tzdata \
     nano \
   && apk add --no-cache --virtual .build-deps \
     build-base \
     autoconf \
     automake \
     bind-tools \
     binutils \
     build-base \
     cmake \
     curl \
     file \
     gcc \
     gd-dev \
     geoip-dev \
     git \
     gnupg \
     libc-dev \
     libstdc++ \
     readline \
     libtool \
     libxslt-dev \
     linux-headers \
     make \
     patch \
     pcre \
     wget \
     pcre-dev \
     perl-dev \
     su-exec \
     tar \
     tzdata \
     zlib-dev \
 && mkdir -p ${COMPILE_DIR} \
 && wget -P $COMPILE_DIR http://nginx.org/download/${VERSION_NGINX}.tar.gz \
 && wget -P $COMPILE_DIR https://github.com/3078825/nginx-image/archive/master.zip \
 && wget -P $COMPILE_DIR http://luajit.org/download/LuaJIT-2.0.5.tar.gz \
 && git clone git://github.com/vozlt/nginx-module-vts.git $COMPILE_DIR/nginx-module-vts \
 && git clone https://github.com/openresty/lua-nginx-module.git $COMPILE_DIR/lua-nginx-module \
 && git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git $COMPILE_DIR/ngx_http_substitutions_filter_module \
 && git clone https://github.com/kvspb/nginx-auth-ldap.git $COMPILE_DIR/nginx-auth-ldap \
 && cd $COMPILE_DIR && tar xzf $VERSION_NGINX.tar.gz \
 && cd $COMPILE_DIR && unzip master.zip  \
 && cd $COMPILE_DIR && tar xzf LuaJIT-2.0.5.tar.gz \
 && cd $COMPILE_DIR/LuaJIT-2.0.5 && make  && make install \
 && cd $COMPILE_DIR/$VERSION_NGINX \
 && ./configure \
--with-ld-opt="-lrt"  \
--with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
--with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,--as-needed' \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--lock-path=/var/lock/nginx.lock \
--pid-path=/run/nginx.pid \
--http-client-body-temp-path=/var/lib/nginx/body \
--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
--http-proxy-temp-path=/var/lib/nginx/proxy \
--http-scgi-temp-path=/var/lib/nginx/scgi \
--http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_flv_module \
--with-file-aio \
--with-http_sub_module \
--with-http_mp4_module \
--with-http_gzip_static_module \
--with-http_stub_status_module \
--with-http_image_filter_module \
--with-threads \
--with-mail \
--with-http_dav_module \
--with-mail_ssl_module \
--with-stream \
--with-stream_realip_module \
--with-stream_ssl_module \
--with-stream_ssl_preread_module \
--with-debug \
--with-pcre-jit \
--with-pcre \
--with-http_stub_status_module \
--with-http_realip_module \
--with-http_gunzip_module \
--with-http_auth_request_module \
--with-http_addition_module \
--with-http_gzip_static_module \
--with-http_random_index_module \
--with-http_secure_link_module \
--add-module=$COMPILE_DIR/ngx_http_substitutions_filter_module \
--add-module=$COMPILE_DIR/lua-nginx-module \
--add-module=$COMPILE_DIR/nginx-auth-ldap \
--add-module=$COMPILE_DIR/nginx-module-vts \
&& cd $COMPILE_DIR/$VERSION_NGINX \
&& make  -j ${NB_PROC} \
&& make install && make clean && rm -rf $COMPILE_DIR/*\
&& apk add --no-cache --virtual .gettext gettext \
  && mv /usr/bin/envsubst /tmp/ \
  && runDeps="$( \
    scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | sort -u \
      | xargs -r apk info --installed \
      | sort -u \
  ) sed tzdata ca-certificates tini shadow" \
  && apk add --no-cache --virtual .nginx-rundeps $runDeps \
  && apk del .build-deps \
  && apk del .gettext \
  && mv /tmp/envsubst /usr/local/bin/ \
  # forward request and error logs to docker log collector
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log \
  && mkdir -p /var/www /var/lib/nginx/body \
  && rm -rf /tmp/* /usr/src/* /var/cache/apk/* /root/.gnupg /libressl* /nginx* || true
  EXPOSE 80 443
  CMD ["nginx", "-g", "daemon off;"]
