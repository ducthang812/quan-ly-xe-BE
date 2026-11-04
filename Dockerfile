# ---- Build ----
FROM eclipse-temurin:17-jdk AS build
WORKDIR /app
COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw -B -q dependency:go-offline
COPY src src
RUN ./mvnw -B -q package -DskipTests

# ---- Run ----
FROM eclipse-temurin:17-jre
WORKDIR /app
ENV TZ=Asia/Ho_Chi_Minh
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
# PORT do nền tảng deploy (Render, Railway...) cấp; mặc định 8080.
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -Dserver.port=${PORT:-8080} -jar /app/app.jar"]
