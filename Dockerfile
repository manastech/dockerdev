FROM golang:1.20-alpine AS build

COPY go.mod go.sum monitor.go /go/src/
RUN cd /go/src && go build monitor.go

FROM jwilder/nginx-proxy:latest AS release

RUN apt-get -q update && \
    apt-get install -y -q --no-install-recommends dnsmasq && \
    apt-get -q clean && rm -r /var/lib/apt/lists/*

# override nginx configs
COPY *.conf /etc/nginx/conf.d/

# override nginx-proxy templating
COPY nginx.tmpl Procfile /app/
COPY --from=build /go/src/monitor /app/

# COPY htdocs /var/www/default/htdocs/

ENV DOMAIN_TLD lvh.me
ENV DNS_IP 127.0.0.1
ENV HOSTMACHINE_IP 127.0.0.1
