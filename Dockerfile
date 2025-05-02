# Build stage
FROM dart:stable AS builder
WORKDIR /app
COPY pubspec.yaml .
RUN dart pub get
COPY . .
RUN dart compile exe bin/server.dart -o server

# Runtime stage
FROM alpine:latest
RUN apk add --no-cache tzdata
WORKDIR /app
COPY --from=builder /app/server /app/server

# Create .env from build arguments
ARG DB_HOST
ARG DB_PORT
ARG DB_NAME
ARG DB_USER
ARG DB_PASSWORD
RUN echo "DB_HOST=$DB_HOST" > .env && \
    echo "DB_PORT=$DB_PORT" >> .env && \
    echo "DB_NAME=$DB_NAME" >> .env && \
    echo "DB_USER=$DB_USER" >> .env && \
    echo "DB_PASSWORD=$DB_PASSWORD" >> .env

EXPOSE 8088
CMD ["./server"]