# syntax=docker/dockerfile:1
# db: H2 Database in server (TCP) mode, running as a non-root user.
# The database files live in /var/lib/h2, which compose.yaml mounts as a named volume.

ARG JRE_IMAGE=eclipse-temurin:17-jre-alpine

# --- Stage 1: download the H2 jar and check it against Maven Central's SHA-1 ---
# curl only exists in this stage; it never reaches the final image.
FROM ${JRE_IMAGE} AS download
ARG H2_VERSION=2.3.232
RUN apk add --no-cache curl
RUN set -eux; \
    url="https://repo1.maven.org/maven2/com/h2database/h2/${H2_VERSION}/h2-${H2_VERSION}.jar"; \
    curl -fsSL --retry 3 -o /tmp/h2.jar      "$url"; \
    curl -fsSL --retry 3 -o /tmp/h2.jar.sha1 "$url.sha1"; \
    echo "$(cut -c1-40 /tmp/h2.jar.sha1)  /tmp/h2.jar" | sha1sum -c -

# --- Stage 2: runtime (JRE only) ---
FROM ${JRE_IMAGE}
ARG H2_VERSION=2.3.232
LABEL org.opencontainers.image.title="cogsi-ca4-db" \
      org.opencontainers.image.description="H2 ${H2_VERSION} in TCP server mode for the Bookstore" \
      org.opencontainers.image.source="https://github.com/Rochaprtisep/cogsi2627-1220788-1231013"

# Dedicated service account; the data folder belongs to it and nobody else can read it
RUN addgroup -S h2 \
 && adduser -S -G h2 -H -h /var/lib/h2 -s /sbin/nologin h2 \
 && mkdir -p /opt/h2 /var/lib/h2 \
 && chown h2:h2 /var/lib/h2 \
 && chmod 0750 /var/lib/h2

COPY --from=download /tmp/h2.jar /opt/h2/h2.jar
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY h2-healthcheck.sh    /usr/local/bin/h2-healthcheck
# Scripts edited on Windows may have CRLF line endings: strip them and make the scripts executable
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh /usr/local/bin/h2-healthcheck \
 && chmod 0755 /usr/local/bin/docker-entrypoint.sh /usr/local/bin/h2-healthcheck

# Defaults; compose.yaml overrides them with values from .env
ENV H2_PORT=9092 \
    H2_DB_NAME=bookstore \
    H2_DATA_DIR=/var/lib/h2 \
    H2_JAVA_OPTS="-Xmx256m"

USER h2
WORKDIR /var/lib/h2
VOLUME ["/var/lib/h2"]
EXPOSE 9092
ENTRYPOINT ["docker-entrypoint.sh"]
