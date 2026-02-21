FROM node:20-slim

LABEL org.opencontainers.image.title="Mapnik XML Generator" \
      org.opencontainers.image.description="CartoCSS to Mapnik XML converter for OpenStreetMap tile rendering" \
      org.opencontainers.image.authors="Maksim Dudka" \
      org.opencontainers.image.url="https://github.com/madudka/tile-server" \
      org.opencontainers.image.source="https://github.com/madudka/tile-server/tree/main/mapnik-xml-generator" \
      org.opencontainers.image.licenses="MIT"

# Install build dependencies for carto and system libraries
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        git \
        python3 \
        make \
        g++ \
        libcairo2-dev \
        libprotobuf-dev \
        protobuf-compiler && \
    npm install -g carto@1.2.0 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy CartoCSS style files
COPY carto-style/ /app/carto-style/

# Copy and make executable generation script
COPY generate.sh /app/generate.sh
RUN chmod +x /app/generate.sh

ENTRYPOINT ["/app/generate.sh"]