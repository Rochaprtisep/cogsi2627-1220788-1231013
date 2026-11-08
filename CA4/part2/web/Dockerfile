# syntax=docker/dockerfile:1
# web: Bookstore (CA1/part2) built with the Gradle wrapper and run on a JRE as a non-root user.
# Build context: CA1/part2 (see compose.yaml). Ignore rules: web/Dockerfile.dockerignore.

# --- Stage 1: build with the full JDK and the Gradle wrapper ---
FROM eclipse-temurin:17-jdk-noble AS build
WORKDIR /src

# Build scripts first, source code after: Docker only rebuilds from the first layer that changed
COPY gradlew settings.gradle gradle.properties ./
COPY gradle/ gradle/
COPY app/build.gradle app/
RUN sed -i 's/\r$//' gradlew && chmod +x gradlew

COPY app/src/main/ app/src/main/
# The cache mount keeps the Gradle distribution and the dependencies between builds,
# without putting them in any layer. bootJar: the tests belong to CI, not to the image.
RUN --mount=type=cache,target=/root/.gradle \
    ./gradlew --no-daemon --console=plain :app:bootJar \
 && find app/build/libs -name '*.jar' ! -name '*-plain.jar' -exec cp {} /bookstore.jar \;

# --- Stage 2: runtime (JRE only: no JDK, no Gradle, no source code) ---
FROM eclipse-temurin:17-jre-alpine
LABEL org.opencontainers.image.title="cogsi-ca4-web" \
      org.opencontainers.image.description="Bookstore Spring Boot application (CA1/part2)" \
      org.opencontainers.image.source="https://github.com/Rochaprtisep/cogsi2627-1220788-1231013"

RUN addgroup -S bookstore \
 && adduser -S -G bookstore -H -h /app -s /sbin/nologin bookstore
WORKDIR /app
# Owned by root and only readable by the service: the application cannot change its own jar
COPY --from=build /bookstore.jar /app/bookstore.jar

USER bookstore
EXPOSE 8080
# The JVM sizes its heap from the container memory limit, not from the host memory
ENV JDK_JAVA_OPTIONS="-XX:MaxRAMPercentage=75.0"
ENTRYPOINT ["java", "-jar", "/app/bookstore.jar"]
