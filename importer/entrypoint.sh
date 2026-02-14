#!/bin/bash
set -euo pipefail

echo "🚀 Starting OSM data import..."

# Validate required environment variables
: "${DB_HOST:?DB_HOST is not set}"
: "${DB_PORT:?DB_PORT is not set}"
: "${DB_USER:?DB_USER is not set}"
: "${DB_NAME:?DB_NAME is not set}"
: "${IMPORT_MODE:=auto}"

# Load database password from secret file or environment
if [ -n "${DB_PASS_FILE:-}" ] && [ -f "${DB_PASS_FILE}" ]; then
  export PGPASSWORD="$(cat "${DB_PASS_FILE}")"
elif [ -n "${DB_PASS:-}" ]; then
  export PGPASSWORD="${DB_PASS}"
else
  echo "❌ ERROR: DB password not provided (set DB_PASS or DB_PASS_FILE)"
  exit 1
fi

# Wait for PostgreSQL to become available
echo "⏳ Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT}..."
RETRIES=60
until pg_isready -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" > /dev/null 2>&1 || [ "${RETRIES}" -eq 0 ]; do
  sleep 2
  RETRIES=$((RETRIES - 1))
done

if [ "${RETRIES}" -eq 0 ]; then
  echo "❌ ERROR: PostgreSQL timeout — service not ready"
  exit 1
fi

# Verify Lua style file exists
LUA_FILE="/home/importer/style/openstreetmap-carto-flex.lua"
if [ ! -f "${LUA_FILE}" ]; then
  echo "❌ ERROR: Lua style file not found: ${LUA_FILE}"
  exit 1
fi

# Discover PBF files for import
mapfile -d '' PBF_FILES < <(find /data -maxdepth 1 -name '*.pbf' -print0 2>/dev/null || true)
if [ "${#PBF_FILES[@]}" -eq 0 ]; then
  echo "❌ ERROR: No .pbf files found in /data/"
  exit 1
fi

echo "📦 Found ${#PBF_FILES[@]} PBF file(s):"
for file in "${PBF_FILES[@]}"; do
  echo "   - $(basename "${file}")"
done

# Determine import mode: create, append, or auto-detect
if [ "${IMPORT_MODE}" = "create" ]; then
  MODE="--create"
  echo "🔧 Import mode: CREATE (fresh import)"
elif [ "${IMPORT_MODE}" = "append" ]; then
  MODE="--append"
  echo "🔧 Import mode: APPEND (incremental update)"
else
  # Auto-detect based on existing OSM tables
  TABLE_EXISTS=$(psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -tAc \
    "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'planet_osm_point');")

  if [ "${TABLE_EXISTS}" = "t" ]; then
    MODE="--append"
    echo "🔧 Auto-detected mode: APPEND (existing tables found)"
  else
    MODE="--create"
    echo "🔧 Auto-detected mode: CREATE (no existing tables)"
  fi
fi

# Execute osm2pgsql import
echo "📥 Importing OSM data with osm2pgsql..."
osm2pgsql \
  --output=flex \
  ${MODE} \
  --slim \
  --database="${DB_NAME}" \
  --host="${DB_HOST}" \
  --port="${DB_PORT}" \
  --username="${DB_USER}" \
  --style="${LUA_FILE}" \
  --cache=2048 \
  --number-processes=4 \
  --hstore \
  "${PBF_FILES[@]}"

# Apply rendering indexes
SQL_DIR="/home/importer/sql"
if [ ! -f "${SQL_DIR}/indexes.sql" ]; then
  echo "❌ ERROR: indexes.sql not found in ${SQL_DIR}/"
  exit 1
fi

echo ".CreateIndexes for rendering performance..."
psql -v ON_ERROR_STOP=1 -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${SQL_DIR}/indexes.sql"

# Apply custom database functions
if [ ! -f "${SQL_DIR}/functions.sql" ]; then
  echo "❌ ERROR: functions.sql not found in ${SQL_DIR}/"
  exit 1
fi

echo "⚙️ Creating database functions..."
psql -v ON_ERROR_STOP=1 -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${SQL_DIR}/functions.sql"

echo "✅ Import completed successfully!"