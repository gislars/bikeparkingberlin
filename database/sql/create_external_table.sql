SET client_min_messages TO WARNING;

CREATE SCHEMA IF NOT EXISTS extern;
CREATE TABLE IF NOT EXISTS extern.external_data (
    id SERIAL,
    city VARCHAR(255) NOT NULL UNIQUE,
    suffix VARCHAR(255) NOT NULL,
    datasource TEXT,
    datasource_link TEXT,
    license TEXT,
    license_link TEXT,
    center_lat FLOAT,
    center_lon FLOAT,
    zoom_level INT,
    admin_osm_id BIGINT,
    is_cluster BOOLEAN DEFAULT false
);

CREATE TABLE IF NOT EXISTS extern.external_feedback (
    id SERIAL,
    suffix VARCHAR(255) NOT NULL,
    osm_user VARCHAR(255),
    do_not_exists BOOLEAN,
    feedback TEXT,
    geom geometry(Geometry,3857)
);

CREATE TABLE IF NOT EXISTS extern.file_feedback (
    id SERIAL,
    suffix VARCHAR(255) NOT NULL,
    osm_user VARCHAR(255),
    obj_id VARCHAR(255),
    feedback TEXT
);
