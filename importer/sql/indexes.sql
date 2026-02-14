-- Rendering performance indexes for OpenStreetMap Carto style

-- Ferry routes
CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_line_ferry
  ON planet_osm_line USING GIST (way)
  WHERE route = 'ferry' AND osm_id > 0;

-- Named roads and routes
CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_line_label
  ON planet_osm_line USING GIST (way)
  WHERE name IS NOT NULL OR ref IS NOT NULL;

-- Waterways
CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_line_waterway
  ON planet_osm_line USING GIST (way)
  WHERE waterway IN ('river', 'canal', 'stream', 'drain', 'ditch');

-- Place points with names
CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_point_place
  ON planet_osm_point USING GIST (way)
  WHERE place IS NOT NULL AND name IS NOT NULL;

-- Administrative boundaries
CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_polygon_admin
  ON planet_osm_polygon USING GIST (ST_PointOnSurface(way))
  WHERE name IS NOT NULL AND boundary = 'administrative' AND admin_level IN ('0', '1', '2', '3', '4');

-- Military areas
CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_polygon_military
  ON planet_osm_polygon USING GIST (way)
  WHERE (landuse = 'military' OR military = 'danger_area') AND building IS NULL;

-- Named polygons
CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_polygon_name
  ON planet_osm_polygon USING GIST (ST_PointOnSurface(way))
  WHERE name IS NOT NULL;

-- Large named polygons (z6+)
CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_polygon_name_z6
  ON planet_osm_polygon USING GIST (ST_PointOnSurface(way))
  WHERE name IS NOT NULL AND way_area > 5980000;

-- Non-building polygons
CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_polygon_nobuilding
  ON planet_osm_polygon USING GIST (way)
  WHERE building IS NULL;

-- Water features
CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_polygon_water
  ON planet_osm_polygon USING GIST (way)
  WHERE waterway IN ('dock', 'riverbank', 'canal')
     OR landuse IN ('reservoir', 'basin')
     OR "natural" IN ('water', 'glacier');

-- Area-based zoom filters
CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_polygon_way_area_z10
  ON planet_osm_polygon USING GIST (way)
  WHERE way_area > 23300;

CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_polygon_way_area_z6
  ON planet_osm_polygon USING GIST (way)
  WHERE way_area > 5980000;

-- Administrative roads
CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_roads_admin
  ON planet_osm_roads USING GIST (way)
  WHERE boundary = 'administrative';

CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_roads_admin_low
  ON planet_osm_roads USING GIST (way)
  WHERE boundary = 'administrative' AND admin_level IN ('0', '1', '2', '3', '4');

-- Roads with references
CREATE INDEX CONCURRENTLY IF NOT EXISTS planet_osm_roads_roads_ref
  ON planet_osm_roads USING GIST (way)
  WHERE highway IS NOT NULL AND ref IS NOT NULL;