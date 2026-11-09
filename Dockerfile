# Build do Flutter Web servido pelo Nginx.
# Execute na raiz deste repositório:
#   docker build -t conecta-vida/mobile-web:latest .
# O Nginx serve o Flutter e encaminha /api para mobile-api:8081
# quando ambos os containers estão na mesma rede Docker.
FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build
WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
ARG API_BASE_URL=/api
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

FROM nginx:1.27-alpine
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1/healthz || exit 1
