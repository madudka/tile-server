#!/bin/bash
set -euo pipefail

echo "⏳ Waiting for PostgreSQL to be ready..."

# Load database password from secret file if provided
if [ -n "${DB_PASS_FILE:-}" ] && [ -f "${DB_PASS_FILE}" ]; then
  DB_PASS="$(cat "${DB_PASS_FILE}")" || exit 1
  export DB_PASS
fi

# Wait for PostgreSQL availability
until pg_isready -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" > /dev/null 2>&1; do
  sleep 2
done

echo "✅ PostgreSQL is ready"

# Import external geospatial data (coastlines, boundaries, etc.)
IMPORT_EXTERNAL_DATA="${IMPORT_EXTERNAL_DATA:-true}"

if [ "${IMPORT_EXTERNAL_DATA}" = "true" ]; then
  echo "📥 Running get-external-data.py..."

  python3 /home/renderer/get-external-data.py \
      --config /home/renderer/external-data.yml \
      --data /etc/renderd/data \
      --host "${DB_HOST}" \
      --port "${DB_PORT}" \
      --user "${DB_USER}" \
      --password "${DB_PASS}" \
      --skip-if-cached \
      --skip-http-check \
      --force-import \
      --verbose

  echo "✅ External data processing completed"
else
  echo "⏭️ Skipping external data import (IMPORT_EXTERNAL_DATA=false)"
fi

# Verify Mapnik XML configuration exists
XML="/etc/mapnik.xml"

if [ ! -f "${XML}" ]; then
  echo "❌ ERROR: ${XML} not found"
  exit 1
fi

# Replace placeholders in Mapnik XML with actual database credentials
USE_PLACEHOLDERS="${USE_PLACEHOLDERS:-false}"

if [ "${USE_PLACEHOLDERS}" = "true" ]; then
  echo "🔧 Patching mapnik.xml with database credentials..."

  tmpfile=$(mktemp)
  trap 'rm -f "$tmpfile"' EXIT

  sed \
    -e "s|{{DB_HOST}}|${DB_HOST}|g" \
    -e "s|{{DB_PORT}}|${DB_PORT}|g" \
    -e "s|{{DB_USER}}|${DB_USER}|g" \
    -e "s|{{DB_PASS}}|${DB_PASS}|g" \
    -e "s|{{DB_NAME}}|${DB_NAME}|g" \
    "${XML}" > "${tmpfile}"

  mv "${tmpfile}" "${XML}"
else
  echo "⏭️ Skipping placeholder patching (USE_PLACEHOLDERS=false)"
fi

# Start renderd daemon in background
echo "🚀 Starting renderd in background..."
renderd -f -c /etc/renderd.conf &

# Wait for renderd socket to be available
while [ ! -S /run/renderd/renderd.sock ]; do
  echo "⏳ Waiting for renderd socket..."
  sleep 1
done

echo "✅ Renderd socket is ready"
echo "🚀 Starting Apache..."

# Run Apache in foreground (replaces current process)
exec apache2ctl -D FOREGROUND