# 🗺️ OSM Tile Server

![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)
![Docker](https://img.shields.io/badge/docker-required-blue.svg)
![PostgreSQL](https://img.shields.io/badge/postgresql-18-blue.svg)
![PostGIS](https://img.shields.io/badge/postgis-3.6-blue.svg)

A complete OpenStreetMap tile server stack based on **PostgreSQL 18**, **PostGIS 3.6**, **renderd**, **Mapnik**, and **Apache**. Designed for offline rendering and customizable map styles.

---

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Configuration](#-configuration)
- [Quick Start](#-quick-start)
- [Usage](#-usage)
- [Updating Data](#-updating-data)
- [⚡ PostgreSQL Performance Tuning](#-postgresql-performance-tuning)
- [🔧 PostGIS Version Management](#-postgis-version-management)
- [🐛 Troubleshooting](#-troubleshooting)
- [📜 License](#-license)
- [👤 Author](#-author)

---

## ✨ Features

- 🗺️ **Full OSM Stack** — PostgreSQL + PostGIS + renderd + Mapnik + Apache
- 🎨 **Customizable Styles** — CartoCSS-based styling with openstreetmap-carto
- 📦 **Offline Operation** — No internet required after initial setup
- 🔒 **Secure Secrets** — Password management via Docker secrets
- 🚀 **Production Ready** — Optimized configuration for rendering performance
- 🌐 **Leaflet Viewer** — Built-in web interface for tile preview
- 🔄 **Incremental Updates** — Append mode for updating map data
- 📊 **Monitoring** — mod_tile statistics endpoint

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Leaflet Viewer                         │
│                         (Port 8081)                         │
└─────────────────────────────┬───────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────┐
│                    Apache + mod_tile                        │
│                       renderd daemon                        │
│                         (Port 8080)                         │
└─────────────────────────────┬───────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────┐
│                       PostgreSQL 18                         │
│                        PostGIS 3.6                          │
│                         (Port 5432)                         │
└─────────────────────────────────────────────────────────────┘
```

**Service Flow:**
1. **postgres** — Spatial database with OSM data
2. **mapnik-xml-generator** — Generates Mapnik XML from CartoCSS (run once)
3. **importer** — Imports OSM PBF data into database (run once or update)
4. **apache-renderd** — Renders and serves tiles via HTTP
5. **leaflet-viewer** — Web interface for tile visualization

---

## 📁 Project Structure

```
tile-server/
├── apache-renderd/          # Apache + renderd + Mapnik tile server
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── mapnik.xml
│   ├── renderd.conf
│   └── symbols/
├── data/                    # OSM PBF data files (place your .osm.pbf here)
│   └── *.osm.pbf
├── importer/                # OSM data importer (osm2pgsql)
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── sql/
│   └── style/
├── leaflet-viewer/          # Web viewer for tiles
│   ├── Dockerfile
│   └── sample_leaflet.html
├── mapnik-xml-generator/    # CartoCSS to Mapnik XML converter
│   ├── Dockerfile
│   ├── generate.sh
│   └── carto-style/
├── postgres/                # PostgreSQL + PostGIS
│   ├── Dockerfile
│   ├── initdb-postgis.sh
│   └── config/
├── secrets/                 # Docker secrets (gitignored)
│   └── postgres_password.txt
├── .env                     # Environment configuration
├── docker-compose.yml
├── LICENSE
└── README.md
```

---

## ⚙️ Configuration

### Environment Variables (`.env`)

Copy `.env.example` to `.env` and customize:

```env
# PostgreSQL Configuration
POSTGRES_USER=renderer                    # Database username
POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password  # Path to password file
POSTGRES_DB=gis                           # Database name

# Database Connection (used by importer, renderd, mapnik)
POSTGRES_HOST=postgres                    # Service name in docker-compose
POSTGRES_PORT=5432                        # PostgreSQL port

# Importer Configuration
IMPORT_MODE=auto                          # auto | create | append
                                      # auto: detects existing tables
                                      # create: fresh import (drops existing)
                                      # append: incremental update

# Renderd Configuration
USE_PLACEHOLDERS=true                     # true | false
                                      # true: patch mapnik.xml with DB credentials
                                      # false: use pre-configured mapnik.xml
IMPORT_EXTERNAL_DATA=true                 # true | false
                                      # true: import coastlines, boundaries, etc.
                                      # false: skip external data import
```

### Secrets

Create `secrets/postgres_password.txt` with your database password:

```bash
mkdir -p secrets
echo "your_secure_password" > secrets/postgres_password.txt
chmod 600 secrets/postgres_password.txt
```

> ⚠️ **Security Note**: Never commit `secrets/` directory to Git. It's already in `.gitignore`.

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/madudka/tile-server
cd tile-server
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your preferences
```

### 3. Prepare Data

Download OSM PBF data from [Geofabrik](https://download.geofabrik.de/) or [BBBike](https://extract.bbbike.org/):

```bash
# Example: Download Belarus
mkdir -p data
wget -P data https://download.geofabrik.de/europe/belarus-latest.osm.pbf
```

Place your `.osm.pbf` files in the `data/` directory.

### 4. Build Images

```bash
docker compose build
```

### 5. Start Database

```bash
docker compose up -d postgres
```

Wait for PostgreSQL to be ready (check logs):

```bash
docker compose logs -f postgres
```

### 6. Generate Mapnik XML (Optional)

If you modified CartoCSS styles, regenerate Mapnik XML:

```bash
docker compose --profile generate-xml up mapnik-xml-generator
```

This creates `apache-renderd/mapnik.xml` with your database credentials.

### 7. Import OSM Data

```bash
docker compose --profile import up importer
```

Import time depends on data size:
- **City**: 5-15 minutes
- **Country**: 30-60 minutes
- **Continent**: 2-6 hours
- **Full planet**: 12-48 hours

### 8. Configure External Data Import

**Important:** For the **first run only**, edit `.env` and set:

```env
IMPORT_EXTERNAL_DATA=true
```

This will download and import external geospatial data (coastlines, boundaries, water polygons) required for proper map rendering.

> 💡 **Note:** After the first successful run, you can set `IMPORT_EXTERNAL_DATA=false` to skip this step on subsequent restarts and speed up startup time.

### 9. Start Tile Server

```bash
docker compose up -d apache-renderd leaflet-viewer
```

### 10. Access Services

| Service | URL | Description |
|---------|-----|-------------|
| **Tile Server** | http://localhost:8080/tiles/{z}/{x}/{y}.png | Rendered tiles |
| **Leaflet Viewer** | http://localhost:8081 | Web interface |
| **mod_tile Stats** | http://localhost:8080/mod_tile | Rendering statistics |

---

## 📖 Usage

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f postgres
docker compose logs -f apache-renderd
```

### Stop Services

```bash
# Stop all services
docker compose down

# Stop specific service
docker compose stop apache-renderd
```

### Restart Services

```bash
# Restart tile server
docker compose restart apache-renderd

# Restart with rebuild
docker compose up -d --force-recreate apache-renderd
```

### Clean Up

```bash
# Stop and remove containers
docker compose down

# Stop, remove containers, and delete volumes (WARNING: deletes all data!)
docker compose down -v

# Remove unused images
docker image prune -a
```

### Access Database

```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U renderer -d gis

# Backup database
docker compose exec postgres pg_dump -U renderer gis > backup.sql

# Restore database
docker compose exec -T postgres psql -U renderer gis < backup.sql
```

### Access Rendered Tiles

Tiles are available at:
```
http://localhost:8080/tiles/{z}/{x}/{y}.png
```

**Example URLs:**
- Zoom 0: `http://localhost:8080/tiles/0/0/0.png`
- Zoom 10: `http://localhost:8080/tiles/10/512/384.png`
- Zoom 18: `http://localhost:8080/tiles/18/132000/89000.png`

### View mod_tile Statistics

```bash
curl http://localhost:8080/mod_tile
```

Output includes:
- Rendered tiles count
- Cache hits/misses
- Queue length
- Render times

---

## 🔄 Updating Data

### Incremental Update (Append Mode)

1. Download updated PBF file
2. Set `IMPORT_MODE=append` in `.env`
3. Run importer:

```bash
docker compose --profile import up importer
```

### Full Reimport (Create Mode)

1. Stop services:

```bash
docker compose down
```

2. Set `IMPORT_MODE=create` in `.env`
3. Remove existing data:

```bash
docker compose down -v
```

4. Reimport:

```bash
docker compose up -d postgres
docker compose --profile import up importer
docker compose up -d apache-renderd leaflet-viewer
```

### Update External Data

If you need to refresh coastlines, boundaries, etc.:

1. Set `IMPORT_EXTERNAL_DATA=true` in `.env`
2. Restart renderd:

```bash
docker compose restart apache-renderd
```

---

## ⚡ PostgreSQL Performance Tuning

> ⚠️ **For Production Deployments Only**  
> These settings are recommended for servers with **16GB+ RAM dedicated to PostgreSQL**.  
> For development/testing environments, default settings are sufficient.  
> **Never use huge pages in Docker** — requires privileged mode and host-level configuration (security risk).

### 📊 Recommended Settings by Dataset Size

| Dataset | CPU Cores | RAM | Disk Space | Disk Type | Notes |
|---------|-----------|-----|------------|-----------|-------|
| **City**<br>(e.g., Minsk) | 2–4 | 4–8 GB | 5–10 GB | SSD | Minimal setup for testing/local use |
| **Country**<br>(e.g., Belarus) | 4–8 | 16–32 GB | 40–80 GB | NVMe SSD | Balanced performance for production |
| **Continent**<br>(e.g., Europe) | 8–16 | 32–64 GB | 300–600 GB | NVMe SSD | Requires aggressive autovacuum tuning |
| **Planet**<br>(full Earth) | 16–32 | 64–128 GB | 1.5–2.5 TB | NVMe RAID | Enterprise-grade setup; consider replication |

### 💡 Rule of Thumb — PostgreSQL Configuration for OSM


| Parameter | Formula / Value | Unit | Description | Critical Notes |
|-----------|-----------------|------|-------------|----------------|
| **`shared_buffers`** | `25%` of container RAM | GB | PostgreSQL internal cache | ⚠️ Max `32GB` (diminishing returns beyond) |
| **`effective_cache_size`** | `50–75%` of **host** RAM | GB | Estimated OS + PG cache (for planner only) | Does not allocate memory |
| **`work_mem`** | `RAM / (max_connections × 2)` | MB | Memory per sort/hash operation | ⚠️ Per operation, not per connection<br>Min: `64MB` • Max: `2GB` |
| **`maintenance_work_mem`** | `10–15%` of container RAM | GB | Memory for `CREATE INDEX`, `VACUUM` | ⚠️ Max `2GB` per worker |
| **`max_connections`** | `20` → `50` → `100` | — | Concurrent connections | dev → prod → planet |
| **`max_worker_processes`** | `CPU cores` | — | Total background workers | Must be ≥ sum of parallel workers |
| **`max_parallel_workers_per_gather`** | `CPU cores / 2` | — | Parallel workers per query | Min: `2` • Max: `4` |
| **`max_parallel_workers`** | `CPU cores` | — | Total parallel workers | |
| **`max_parallel_maintenance_workers`** | `CPU cores / 4` | — | Parallel `CREATE INDEX`, `VACUUM` | Min: `2` • Max: `4` |
| **`wal_buffers`** | `16MB` | MB | WAL write buffer | Fixed value |
| **`max_wal_size`** | `4GB` → `16GB` | GB | Max WAL before checkpoint | country → planet |
| **`min_wal_size`** | `1GB` → `4GB` | GB | Min WAL to prevent frequent checkpoints | country → planet |
| **`checkpoint_completion_target`** | `0.9` | — | Spread checkpoint over 90% of interval | Reduces I/O spikes |
| **`random_page_cost`** | `1.1` → `1.25` → `4.0` | — | Cost of random disk read | NVMe → SSD → HDD |
| **`effective_io_concurrency`** | `200` → `2` | — | Async I/O operations | NVMe/SSD → HDD<br>⚠️ Only for `random_page_cost < 2.0` |
| **`autovacuum_max_workers`** | `6` → `10` | — | Concurrent autovacuum workers | Critical for OSM data |
| **`autovacuum_vacuum_scale_factor`** | `0.05` | — | Trigger `VACUUM` at 5% dead tuples | Default is `0.20` (too high for OSM) |
| **`autovacuum_analyze_scale_factor`** | `0.02` | — | Trigger `ANALYZE` at 2% changes | Default is `0.10` |
| **`autovacuum_vacuum_cost_delay`** | `10ms` | ms | Pause between vacuum work | Lower = more aggressive |
| **`max_locks_per_transaction`** | `256` → `1024` | — | Max locks per transaction | Increase for planet imports |
| **`huge_pages`** | `off` | — | Use huge memory pages | ⚠️ **Always `off` in Docker** (security risk) |

### ⚠️ Critical Warnings

1. **Never set `shared_buffers > 32GB`** — diminishing returns due to PostgreSQL internal locking
2. **Always set `huge_pages = off` in Docker** — huge pages require privileged mode and host configuration
3. **Reserve 20-30% RAM for OS and other services** — never allocate 100% to PostgreSQL

---

## 🔧 PostGIS Version Management

The PostgreSQL Dockerfile pins the PostGIS version for build reproducibility. This version may need periodic updates as new releases become available.

### Current Version

```dockerfile
ENV POSTGIS_VERSION=3.6.2+dfsg-1.pgdg130+1
```

### Finding Available Versions

To check available PostGIS versions in the official repository:

```bash
docker run --rm postgres:18-trixie bash -c "
  apt-get update > /dev/null 2>&1 &&
  apt-get install -y --no-install-recommends wget ca-certificates gnupg > /dev/null 2>&1 &&
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg &&
  echo 'deb http://apt.postgresql.org/pub/repos/apt/ trixie-pgdg main 18' > /etc/apt/sources.list.d/pgdg.list &&
  apt-get update > /dev/null 2>&1 &&
  apt-cache madison postgresql-18-postgis-3
"
```

### Updating the Version

1. Edit `postgres/Dockerfile`:
   ```dockerfile
   ENV POSTGIS_VERSION=<new_version>
   ```

2. Rebuild the image:
   ```bash
   docker compose build postgres
   ```

3. Verify installation:
   ```bash
   docker compose exec postgres psql -U renderer -d gis -c "SELECT PostGIS_Version();"
   ```

### Repository Reference

- **APT Repository:** https://apt.postgresql.org/pub/repos/apt/pool/main/p/postgis/
- **PostGIS Releases:** https://postgis.net/source/

---

## 🐛 Troubleshooting

### PostgreSQL not ready

```bash
# Check PostgreSQL logs
docker compose logs postgres

# Wait for service to be healthy
docker compose ps
```

### Importer fails

```bash
# Check importer logs
docker compose logs importer

# Verify PBF files exist
ls -lh data/*.osm.pbf

# Check database connection
docker compose exec postgres pg_isready -U renderer -d gis
```

### Tiles not rendering

```bash
# Check renderd logs
docker compose logs apache-renderd

# Verify renderd socket exists
docker compose exec apache-renderd ls -la /run/renderd/

# Check Mapnik XML
docker compose exec apache-renderd cat /etc/mapnik.xml | head -100
```

### Port already in use

Change ports in `docker-compose.yml`:

```yaml
apache-renderd:
  ports:
    - "8082:80"  # Changed from 8080

leaflet-viewer:
  ports:
    - "8083:80"  # Changed from 8081
```

---

## 📜 License

- **Code** (Dockerfiles, scripts, configs): [MIT License](LICENSE)
- **Map Data** (OpenStreetMap): [ODbL](https://opendatacommons.org/licenses/odbl/)
- **Dependencies** (PostgreSQL, PostGIS, renderd, etc.): See respective licenses

---

## 👤 Author

**Maksim Dudka**  
GitHub: [@madudka](https://github.com/madudka)  
Project: https://github.com/madudka/tile-server

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📚 References

- [OpenStreetMap](https://www.openstreetmap.org/)
- [PostGIS](https://postgis.net/)
- [osm2pgsql](https://osm2pgsql.org/)
- [Mapnik](https://mapnik.org/)
- [mod_tile](https://github.com/openstreetmap/mod_tile)
- [Leaflet](https://leafletjs.com/)
- [Geofabrik Downloads](https://download.geofabrik.de/)

---

## 🙏 Acknowledgments

This project is based on and inspired by:
- [openstreetmap-tile-server](https://github.com/Overv/openstreetmap-tile-server)
- [docker-postgis](https://github.com/postgis/docker-postgis)
- [openstreetmap-carto](https://github.com/gravitystorm/openstreetmap-carto)

---

**Happy Mapping! 🗺️**