# Build stage
FROM dart:stable AS builder
WORKDIR /app
COPY pubspec.* .
RUN dart pub get
COPY . .
RUN dart compile exe bin/server.dart -o server

# Runtime stage
FROM alpine:latest
RUN apk add --no-cache tzdata
WORKDIR /app
COPY --from=builder /app/server /app/server
COPY --from=builder /app/.env /app/.env

EXPOSE 8088
CMD ["./server"]