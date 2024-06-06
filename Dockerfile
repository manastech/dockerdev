# BUILD image
FROM crystallang/crystal:1.8-alpine AS build
COPY . /src
RUN cd /src && shards build --release --static

# RELEASE image
FROM jwilder/nginx-proxy:latest AS release

RUN apt-get -q update && \
    apt-get install -y -q --no-install-recommends dnsmasq && \
    apt-get -q clean && rm -r /var/lib/apt/lists/*

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
