FROM azul/zulu-openjdk-alpine:21-jre

ARG JAR_FILE=target/ras-backend-*.jar
COPY ${JAR_FILE} /app/ras-backend.jar

ENV JAVA_OPTS="-Xms2048m -Xmx4096m"
ENV SPRING_PROFILES_ACTIVE=""

EXPOSE 8080 9090

ENTRYPOINT exec java $JAVA_OPTS -jar /app/ras-backend.jar
