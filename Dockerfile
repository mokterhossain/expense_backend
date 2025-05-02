# Build stage
FROM dart:stable AS builder
WORKDIR /app
COPY pubspec.yaml .
RUN dart pub get
COPY . .
RUN dart compile exe bin/server.dart -o server

# Runtime stage
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/server /app/server
COPY --from=builder /app/.env /app/.env

EXPOSE 8089
CMD ["./server"]