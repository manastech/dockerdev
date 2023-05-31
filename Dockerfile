# BUILD image
FROM crystallang/crystal:1.8-alpine AS build
COPY . /src
RUN cd /src && shards build --release --static

# RELEASE image
FROM jwilder/nginx-proxy:alpine AS release
RUN apk add --no-cache dnsmasq

# override nginx configs & nginx-proxy templating
COPY *.conf /etc/nginx/conf.d/
COPY nginx.tmpl Procfile /app/

# install executable
COPY --from=build /src/bin/monitor /app/

# default configuration
ENV DOMAIN_TLD lvh.me
ENV NETWORK_NAME shared
ENV DNS_IP 127.0.0.1
ENV HOSTMACHINE_IP 127.0.0.1
