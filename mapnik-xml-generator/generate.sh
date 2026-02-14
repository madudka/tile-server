#!/bin/bash
set -euo pipefail

echo "🔄 Generating mapnik.xml..."

STYLE_DIR="/app/style"
OUTPUT_DIR="/output"

# Determine generation mode: placeholders or real values
USE_PLACEHOLDERS="${USE_PLACEHOLDERS:-false}"
echo "🔧 Generation mode: USE_PLACEHOLDERS=${USE_PLACEHOLDERS}"

# Load database password from file if provided
if [ -n "${DB_PASS_FILE:-}" ] && [ -f "${DB_PASS_FILE}" ]; then
  export DB_PASS="$(cat "${DB_PASS_FILE}")"
fi

# Validate required environment variables (skip if using placeholders)
if [ "${USE_PLACEHOLDERS}" = "false" ]; then
  for var in DB_HOST DB_PORT DB_NAME DB_USER DB_PASS; do
    if [ -z "${!var:-}" ]; then
      echo "❌ Error: variable ${var} is not set"
      exit 1
    fi
  done
fi

# Copy offline carto-style to working directory
echo "📁 Using offline carto-style"
rm -rf "${STYLE_DIR}"
mkdir -p "${STYLE_DIR}"
cp -r /app/carto-style/* "${STYLE_DIR}/"

cd "${STYLE_DIR}"

# Verify project.mml exists
if [ ! -f project.mml ]; then
  echo "❌ Error: project.mml not found in ${STYLE_DIR}"
  exit 1
fi

# Backup original project.mml
if [ ! -f project.mml.bak ]; then
  cp project.mml project.mml.bak
fi

echo "🔧 Injecting database parameters into project.mml..."

# Replace database credentials with placeholders or real values
if [ "${USE_PLACEHOLDERS}" = "true" ]; then
  echo "🔧 Using placeholders"

  perl -i -pe '
    s/host: .*/host: "{{DB_HOST}}"/;
    s/port: .*/port: "{{DB_PORT}}"/;
    s/dbname: .*/dbname: "{{DB_NAME}}"/;
    s/user: .*/user: "{{DB_USER}}"/;
    s/password: .*/password: "{{DB_PASS}}"/;
  ' project.mml

else
  echo "🔧 Using real values"

  perl -i -pe "
    s/host: .*/host: \"${DB_HOST}\"/;
    s/port: .*/port: ${DB_PORT}/;
    s/dbname: .*/dbname: \"${DB_NAME}\"/;
    s/user: .*/user: \"${DB_USER}\"/;
    s/password: .*/password: \"${DB_PASS}\"/;
  " project.mml
fi

# Generate Mapnik XML from CartoCSS
echo "🎨 Generating XML..."
mkdir -p "${OUTPUT_DIR}"
carto project.mml > "${OUTPUT_DIR}/mapnik.xml"

echo "✅ mapnik.xml successfully saved to ${OUTPUT_DIR}/"