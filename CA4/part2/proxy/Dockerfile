# proxy: Nginx reverse proxy, the only entry point from the host.
FROM nginx:1.28-alpine
LABEL org.opencontainers.image.title="cogsi-ca4-proxy" \
      org.opencontainers.image.description="Nginx reverse proxy for the Bookstore" \
      org.opencontainers.image.source="https://github.com/Rochaprtisep/cogsi2627-1220788-1231013"

# At startup, the official image renders /etc/nginx/templates/*.template with envsubst
# into /etc/nginx/conf.d/ (default.conf.template -> default.conf, replacing the default site)
COPY templates/ /etc/nginx/templates/
RUN sed -i 's/\r$//' /etc/nginx/templates/*.template

# Defaults; compose.yaml overrides them with values from .env
ENV NGINX_PORT=80 \
    BACKEND_HOST=web \
    BACKEND_PORT=8080 \
    PROXY_CONNECT_TIMEOUT=5s \
    PROXY_READ_TIMEOUT=30s
EXPOSE 80
