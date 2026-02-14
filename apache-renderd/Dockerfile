FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="Apache Renderd Tile Server" \
      org.opencontainers.image.description="Apache web server with renderd daemon and mod_tile for OSM tile rendering" \
      org.opencontainers.image.authors="Maksim Dudka" \
      org.opencontainers.image.url="https://github.com/madudka/tile-server" \
      org.opencontainers.image.source="https://github.com/madudka/tile-server/tree/main/apache-renderd" \
      org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    APACHE_LOG_DIR=/var/log/apache2 \
    GDAL_DATA=/usr/share/gdal

# Install Apache, renderd, Mapnik and dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        apache2 \
        libapache2-mod-tile \
        renderd \
        mapnik-utils \
        libmapnik3.1 \
        fonts-noto-core \
        fonts-noto-cjk \
        fonts-noto-hinted \
        fonts-dejavu-core \
        fonts-unifont \
        fonts-hanazono \
        curl \
        ca-certificates \
        postgresql-client \
        gdal-bin \
        gdal-data \
        fontconfig \
        python3 \
        python3-pip \
        python3-yaml \
        python3-requests \
        python3-psycopg2 && \
    fc-cache -fv && \
    a2enmod tile expires headers && \
    mkdir -p /var/run/apache2 /var/lock/apache2 /var/run/renderd /var/lib/mod_tile && \
    useradd --create-home --shell /bin/bash renderer && \
    usermod -aG www-data renderer && \
    chown -R renderer:renderer /var/run/renderd /var/lib/mod_tile && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install additional Noto fonts
RUN curl -fsSL "https://github.com/notofonts/noto-fonts/raw/refs/heads/main/archive/hinted/NotoSansTibetan/NotoSansTibetan-Regular.ttf" \
        -o /usr/share/fonts/truetype/noto/NotoSansTibetan-Regular.ttf && \
    curl -fsSL "https://github.com/notofonts/noto-fonts/raw/refs/heads/main/archive/hinted/NotoSansTibetan/NotoSansTibetan-Bold.ttf" \
        -o /usr/share/fonts/truetype/noto/NotoSansTibetan-Bold.ttf && \
    curl -fsSL "https://github.com/notofonts/noto-fonts/raw/refs/heads/main/archive/unhinted/NotoSansSyriac/NotoSansSyriacEastern-Regular.ttf" \
        -o /usr/share/fonts/truetype/noto/NotoSansSyriacEastern-Regular.ttf && \
    curl -fsSL "https://github.com/jenskutilek/free-fonts/raw/refs/heads/master/Noto/Noto%20Emoji/TTF/NotoEmoji-Regular.ttf" \
        -o /usr/share/fonts/truetype/noto/NotoEmoji-Regular.ttf && \
    fc-cache -fv

# Redirect Apache logs to stdout/stderr
RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log

# Copy renderd configuration and resources
COPY --chown=renderer:renderer renderd.conf /etc/renderd.conf
COPY --chown=renderer:renderer mapnik.xml /etc/mapnik.xml
COPY --chown=renderer:renderer symbols/ /etc/symbols/
COPY --chown=renderer:renderer get-external-data.py /home/renderer/get-external-data.py
COPY --chown=renderer:renderer external-data.yml /home/renderer/external-data.yml
COPY --chown=renderer:renderer external-data /etc/renderd/data

RUN mkdir -p /etc/renderd/data && \
    chmod +x /home/renderer/get-external-data.py

# Configure Apache virtual host
RUN a2dissite 000-default && \
    a2enmod headers

COPY mod_tile/renderd.conf /etc/apache2/conf-available/renderd.conf
COPY apache.conf /etc/apache2/sites-available/tile-server.conf

RUN a2ensite tile-server.conf && \
    a2enconf renderd

# Copy and configure entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80 6789

ENTRYPOINT ["/entrypoint.sh"]