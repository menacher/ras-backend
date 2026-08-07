FROM azul/zulu-openjdk-alpine:21-jre

# The executable jar carries the "boot" classifier (see pom.xml). Glob *-boot.jar, never
# *.jar: with classifier=boot the plain target/ras-backend-<version>.jar is the THIN
# pre-repackage jar, a bare *.jar matches BOTH, and COPY with several matches does not
# error -- BuildKit silently keeps the last in sort order, which is the thin one. That is
# how a 28 KB jar with no Main-Class reached the Bulwark demo twice on 2026-08-07.
ARG JAR_FILE=target/ras-backend-*-boot.jar
COPY ${JAR_FILE} /app/ras-backend.jar

# Fail the BUILD, not the container's first second, if the wrong jar was copied. Without
# this the only symptom is "no main manifest attribute" from a pod that has already
# replaced a working one -- and ras-backend deploys with strategy: Recreate, so the good
# pod is gone before the bad one crashes. unzip and grep are both busybox built-ins here.
RUN unzip -p /app/ras-backend.jar META-INF/MANIFEST.MF \
      | grep -q '^Main-Class: org.springframework.boot.loader' \
    || { echo "FATAL: /app/ras-backend.jar is not a Spring Boot executable jar (no Main-Class). Did repackage run?" >&2; exit 1; }

ENV JAVA_OPTS="-Xms2048m -Xmx4096m"
ENV SPRING_PROFILES_ACTIVE=""

EXPOSE 8080 9090

ENTRYPOINT exec java $JAVA_OPTS -jar /app/ras-backend.jar
