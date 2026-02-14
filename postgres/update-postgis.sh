#!/bin/sh
set -e

# Switch to PostgreSQL user context
export PGUSER="${POSTGRES_USER}"

# Extract semantic version (strip build metadata)
POSTGIS_VERSION="${POSTGIS_VERSION%%+*}"

# Update PostGIS extensions in specified databases
for DB in template_postgis "${POSTGRES_DB}" "${@}"; do
  psql --dbname="${DB}" -c "
    CREATE EXTENSION IF NOT EXISTS postgis VERSION '${POSTGIS_VERSION}';
    ALTER EXTENSION postgis UPDATE TO '${POSTGIS_VERSION}';

    CREATE EXTENSION IF NOT EXISTS postgis_topology VERSION '${POSTGIS_VERSION}';
    ALTER EXTENSION postgis_topology UPDATE TO '${POSTGIS_VERSION}';

    CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
    CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder VERSION '${POSTGIS_VERSION}';
    ALTER EXTENSION postgis_tiger_geocoder UPDATE TO '${POSTGIS_VERSION}';
  "
done