FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="OSM Data Importer" \
      org.opencontainers.image.description="OSM PBF data importer using osm2pgsql with flex output for tile rendering" \
      org.opencontainers.image.authors="Maksim Dudka" \
      org.opencontainers.image.url="https://github.com/madudka/tile-server" \
      org.opencontainers.image.source="https://github.com/madudka/tile-server/tree/main/importer" \
      org.opencontainers.image.licenses="MIT"

# Install osm2pgsql and PostgreSQL client tools
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        osm2pgsql \
        postgresql-client \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash importer

USER importer
WORKDIR /home/importer

# Copy Lua style and SQL scripts with proper ownership
COPY --chown=importer:importer style/ /home/importer/style/
COPY --chown=importer:importer sql/ /home/importer/sql/

# Copy and make executable entrypoint script
COPY --chown=importer:importer entrypoint.sh /home/importer/entrypoint.sh
RUN chmod +x /home/importer/entrypoint.sh

ENTRYPOINT ["/home/importer/entrypoint.sh"]