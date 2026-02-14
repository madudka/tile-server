#!/bin/bash
set -e

# Switch to PostgreSQL user context
export PGUSER="${POSTGRES_USER}"

# Create reusable template database with PostGIS support
"${psql[@]}" <<- 'EOSQL'
CREATE DATABASE template_postgis IS_TEMPLATE true;
EOSQL

# Enable spatial extensions in both template and application database
for DB in template_postgis "${POSTGRES_DB}"; do
    echo "Loading PostGIS extensions into ${DB}"
    "${psql[@]}" --dbname="${DB}" <<- 'EOSQL'
        CREATE EXTENSION IF NOT EXISTS postgis;
        CREATE EXTENSION IF NOT EXISTS postgis_topology;
        \c
        CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
        CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;
        CREATE EXTENSION IF NOT EXISTS hstore;
EOSQL
done