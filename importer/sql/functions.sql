-- Access restriction normalization functions for cartographic rendering
CREATE OR REPLACE FUNCTION carto_int_access(accessvalue text, allow_restricted boolean)
RETURNS text
LANGUAGE SQL
IMMUTABLE PARALLEL SAFE
AS $$
SELECT
	CASE
		WHEN accessvalue IN ('yes', 'designated', 'permissive') THEN 'yes'
		WHEN accessvalue IN ('destination',  'delivery', 'customers') THEN
			CASE WHEN allow_restricted = TRUE  THEN 'restricted' ELSE 'yes' END
		WHEN accessvalue IN ('no', 'permit', 'private', 'agricultural', 'forestry', 'agricultural;forestry') THEN 'no'
		WHEN accessvalue IS NULL THEN NULL
		ELSE 'unrecognised'
	END
$$;

-- Path type promotion based on access tags
CREATE OR REPLACE FUNCTION carto_path_type(bicycle text, horse text)
RETURNS text
LANGUAGE SQL
IMMUTABLE PARALLEL SAFE
AS $$
SELECT
	CASE
		WHEN bicycle = 'designated' THEN 'cycleway'
		WHEN horse = 'designated' THEN 'bridleway'
		ELSE 'path'
	END
$$;

-- Unified access evaluation for highway rendering
CREATE OR REPLACE FUNCTION carto_highway_int_access(
	highway text, 
	"access" text, 
	foot text, 
	bicycle text, 
	horse text, 
	motorcar text, 
	motor_vehicle text, 
	vehicle text
)
RETURNS text
LANGUAGE SQL
IMMUTABLE PARALLEL SAFE
AS $$
SELECT
	CASE
		WHEN highway IN (
			'motorway', 'motorway_link', 'trunk', 'trunk_link', 'primary', 'primary_link', 
			'secondary', 'secondary_link', 'tertiary', 'tertiary_link', 'residential', 
			'unclassified', 'living_street', 'service', 'road'
		) THEN carto_int_access(
				COALESCE(
					NULLIF(motorcar, 'unknown'),
					NULLIF(motor_vehicle, 'unknown'),
					NULLIF(vehicle, 'unknown'),
					"access"
				),
				TRUE
		)
		WHEN highway = 'path' THEN
			CASE carto_path_type(bicycle, horse)
				WHEN 'cycleway' THEN carto_int_access(bicycle, FALSE)
				WHEN 'bridleway' THEN carto_int_access(horse, FALSE)
				ELSE carto_int_access(COALESCE(NULLIF(foot, 'unknown'), "access"), FALSE)
			END
		WHEN highway = 'pedestrian' THEN carto_int_access(COALESCE(NULLIF(foot, 'unknown'), "access"), TRUE)
		WHEN highway IN ('footway', 'steps') THEN carto_int_access(COALESCE(NULLIF(foot, 'unknown'), "access"), FALSE)
		WHEN highway = 'cycleway' THEN carto_int_access(COALESCE(NULLIF(bicycle, 'unknown'), "access"), FALSE)
		WHEN highway = 'bridleway' THEN carto_int_access(COALESCE(NULLIF(horse, 'unknown'), "access"), FALSE)
		ELSE carto_int_access("access", TRUE)
	END
$$;