FROM openjdk:17-jdk-slim AS builder
WORKDIR /app

# 의존성 캐싱을 위해 build.gradle과 gradle 폴더 먼저 복사
COPY build.gradle settings.gradle gradlew ./
COPY gradle ./gradle

RUN chmod +x gradlew && ./gradlew dependencies --no-daemon

# 소스 복사는 빌드 단계에서만 진행 (불필요한 파일 제외)
COPY src ./src
RUN ./gradlew clean build -x test --no-daemon

# 최종 경량 이미지 사용
FROM openjdk:17-jdk-slim
WORKDIR /app

COPY --from=builder /app/build/libs/*.jar app.jar

ENV SPRING_PROFILES_ACTIVE=docker \
    BASE_UPLOAD_DIR=/app/uploads

RUN mkdir -p "$BASE_UPLOAD_DIR"

CMD ["java", "-jar", "app.jar"]