# CA5 Part 2 - Bookstore with an embedded H2 database (app and DB in the same container, as in CA4 Part 1).
# The build context is prepared by the pipeline: this Dockerfile + bookstore.jar (the jar that passed the tests).
FROM eclipse-temurin:17-jre-alpine

ARG APP_VERSION=dev
ARG GIT_COMMIT=unknown
LABEL org.opencontainers.image.title="cogsi-ca5-bookstore" \
      org.opencontainers.image.version="$APP_VERSION" \
      org.opencontainers.image.revision="$GIT_COMMIT" \
      org.opencontainers.image.source="https://github.com/Rochaprtisep/cogsi2627-1220788-1231013"

# Non-root service account; only the data folder is writable
RUN addgroup -S bookstore \
 && adduser -S -G bookstore -H -h /app -s /sbin/nologin bookstore \
 && mkdir -p /app/data \
 && chown bookstore:bookstore /app/data

WORKDIR /app
COPY bookstore.jar /app/bookstore.jar

USER bookstore
VOLUME /app/data
EXPOSE 8080

# H2 in file mode inside the container; the volume keeps the data between deploys
ENV SPRING_DATASOURCE_URL=jdbc:h2:file:/app/data/bookstore \
    SERVICE_ENVIRONMENT=production \
    JDK_JAVA_OPTIONS="-XX:MaxRAMPercentage=75.0"

HEALTHCHECK --interval=15s --timeout=3s --start-period=60s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health | grep -q '"status":"UP"' || exit 1

ENTRYPOINT ["java", "-jar", "/app/bookstore.jar"]
