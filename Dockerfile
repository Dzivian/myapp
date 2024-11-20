FROM maven:3.9.4-eclipse-temurin-17 AS builder

WORKDIR /app

LABEL maintainer="Yaroslav <yaroslav.sukhodolskiy@umbrellait.com>"

ARG MAVEN_CLI_OPTS=-DskipTests

COPY pom.xml .

RUN mvn dependency:resolve

COPY src ./src

RUN mvn clean package ${MAVEN_CLI_OPTS}

FROM nginx:1.25-alpine

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk \
    APP_NAME=myapp

WORKDIR /app

RUN apk add --no-cache openjdk17-jre

COPY --from=builder /app/target/myapp-0.0.1-SNAPSHOT.jar /app/app.jar
COPY nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/run/nginx && \
    mkdir -p /var/cache/nginx/client_temp

EXPOSE 80

VOLUME /var/log/nginx

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl --fail http://localhost:80 || exit 1

ARG APP_PORT=8080

USER root

STOPSIGNAL SIGQUIT

SHELL ["/bin/sh", "-c"]

ENTRYPOINT ["sh", "-c", "java -jar /app/app.jar & nginx -g 'daemon off;'"]