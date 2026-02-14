FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="Leaflet Tile Viewer" \
      org.opencontainers.image.description="Offline-capable Leaflet web viewer for OpenStreetMap tiles" \
      org.opencontainers.image.authors="Maksim Dudka" \
      org.opencontainers.image.url="https://github.com/madudka/tile-server" \
      org.opencontainers.image.source="https://github.com/madudka/tile-server/tree/main/leaflet-viewer" \
      org.opencontainers.image.licenses="MIT"

# Install Apache and curl for downloading assets
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        apache2 curl ca-certificates && \
    mkdir -p /var/lock/apache2 /var/run/apache2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy Leaflet assets (CSS, JS) to web directory
COPY assets/ /var/www/html/assets/

# Copy viewer HTML page
COPY index.html /var/www/html/

# Set proper ownership and permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Redirect Apache logs to stdout/stderr for Docker logging
RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log

EXPOSE 80

CMD ["apache2ctl", "-D", "FOREGROUND"]