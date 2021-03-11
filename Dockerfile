FROM openjdk:15-jdk-slim as build

WORKDIR application

COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src
RUN ["chmod", "u+x", "mvnw"]

RUN ./mvnw install -DskipTests

RUN cp /application/target/*.jar app.jar
RUN java -Djarmode=layertools -jar app.jar extract
RUN ./mvnw install -DskipTests
RUN mkdir -p target/dependency && (cd target/dependency; jar -xf ../*.jar)

FROM openjdk:15-jdk-slim
WORKDIR application
COPY --from=build application/dependencies/ ./
COPY --from=build application/spring-boot-loader/ ./
COPY --from=build application/snapshot-dependencies/ ./
COPY --from=build application/application/ ./
EXPOSE 8761
ENV JAVA_TOOL_OPTIONS "-Xms128m -Xmx256m"
ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]
