# ---------- Build stage ----------
FROM maven:3.9.6-amazoncorretto-17 AS build
WORKDIR /workspace

# Cache dependencies
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw -q -DskipTests dependency:go-offline

# Build the jar
COPY src/ src/
RUN ./mvnw -DskipTests package

# ---------- Runtime stage ----------
FROM amazoncorretto:17-alpine
# Run as non-root
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

WORKDIR /app
COPY --from=build /workspace/target/*SNAPSHOT*.jar /app/app.jar

EXPOSE 8080
ENV JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0"
ENTRYPOINT ["java","-jar","/app/app.jar"]
