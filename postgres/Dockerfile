FROM postgres:18-trixie

LABEL org.opencontainers.image.title="PostgreSQL with PostGIS" \
      org.opencontainers.image.description="PostgreSQL 18 with PostGIS 3.6 spatial database extension for OSM tile server" \
      org.opencontainers.image.authors="Maksim Dudka" \
      org.opencontainers.image.url="https://github.com/madudka/tile-server" \
      org.opencontainers.image.source="https://github.com/madudka/tile-server/tree/main/postgres" \
      org.opencontainers.image.licenses="MIT"

ENV POSTGIS_MAJOR=3
ENV POSTGIS_VERSION=3.6.2+dfsg-1.pgdg13+1

# Install PostGIS extensions and dependencies
RUN apt-get update \
      && apt-cache showpkg postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
      && apt-get install -y --no-install-recommends \
           ca-certificates \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts \
      && rm -rf /var/lib/apt/lists/*

# Initialize PostGIS extensions on first run
RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/10_postgis.sh
RUN chmod -x /docker-entrypoint-initdb.d/10_postgis.sh

# Provide script for PostGIS extension updates
COPY ./update-postgis.sh /usr/local/bin
RUN chmod +x /usr/local/bin/update-postgis.sh