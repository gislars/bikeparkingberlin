#!/bin/bash

# goto this path
cd `dirname $(readlink -f $0)`

source ../config
source ./tools/bash_functions.sh

mkdir -p external_data

# Download data if not exists
if [ ! -f external_data/s_Fahrradstaender.gml ]
then
    echo "Download Berlin Fahrradständer Befahrung 2014"
    wget -O external_data/s_Fahrradstaender.gml https://fbinter.stadt-berlin.de/fb/wfs/data/senstadt/s_Fahrradstaender\?service\=WFS\&version\=1.1.0\&request\=GetFeature\&typeName\=fis:s_Fahrradstaender
fi

if [ ! -f external_data/13_Bike_und_ride.csv ]
then
    echo "Download Norderstedt Fahhradabstellanlagen an ÖPNV-Haltestellen"
    wget -O external_data/13_Bike_und_ride.csv http://185.223.104.6/data/norderstedt/13_Bike_und_ride.csv
fi

if [ ! -f external_data/fahrradabstellanlagen_jena.csv ]
then
    echo "Download Jena Fahrradabstellanlagen"
    wget -O external_data/fahrradabstellanlagen_jena.csv https://opendata.jena.de/data/fahrradabstellanlagen.csv
fi

if [ ! -f external_data/fahrradabstellanlagen_rostock.csv ]
then
    echo "Download Rostock Fahrradabstellanlagen"
    wget -O external_data/fahrradabstellanlagen_rostock.csv https://geo.sv.rostock.de/download/opendata/fahrradabstellanlagen/fahrradabstellanlagen.csv
fi

# Check ogr2ogr
if [ -z `which ogr2ogr` ]
then
    echo "Please install ogr2ogr e.g. 'apt install gdal-bin'"
    exit 1
fi

# Import data
psql -f sql/create_external_table.sql
echo "Importing External Data ..."

# Berlin Fahrradständer
echo "Import Berlin Fahrradständer Befahrung 2014"
ogr2ogr -f "PostgreSQL" PG:"host=$PGHOST port=$PGPORT dbname=$PGDATABASE user=$PGUSER password=$PGPASSWORD" \
    -progress -overwrite -lco GEOMETRY_NAME=geom \
    -s_srs EPSG:25833 -t_srs EPSG:3857 \
    external_data/s_Fahrradstaender.gml
# create views and entry in external_data   
psql -f sql/create_external_berlin.sql

# Norderstedt Fahrrad ÖPNV
echo "Import Norderstedt Fahhradabstellanlagen an ÖPNV-Haltestellen"
psql -f sql/create_external_noderstedt.sql
cat external_data/13_Bike_und_ride.csv | psql -c "COPY all_parking_nstedt(IDENT,BEZEICH,OEPNV,ART,ANZAHL,X,Y) FROM STDIN DELIMITER ';' CSV HEADER;"
psql -c "UPDATE all_parking_nstedt SET ogc_fid=IDENT, geom=ST_TRANSFORM(ST_SetSRID(ST_MakePoint(X, Y),32632),3857)"

# Jena Fahrradabstellanlagen
echo "Import Jena Fahrradabstellanlagen"
psql -f sql/create_external_jena.sql
cat external_data/fahrradabstellanlagen_jena.csv | psql -c "COPY all_parking_jena(id,org_lat,org_lon,name) FROM STDIN DELIMITER ',' CSV HEADER;"
psql -c "UPDATE all_parking_jena SET ogc_fid=id, geom=ST_TRANSFORM(ST_SetSRID(ST_MakePoint(org_lon, org_lat),4326),3857)"

# Rostock Fahrradabstellanlagen
echo "Import Rostock Fahrradabstellanlagen"
psql -f sql/create_external_rostock.sql
cat external_data/fahrradabstellanlagen_rostock.csv | psql -c "COPY all_parking_rostock(org_lat,org_lon,uuid,kreis_name,kreis_schluessel,gemeindeverband_name,gemeindeverband_schluessel,gemeinde_name,gemeinde_schluessel,gemeindeteil_name,gemeindeteil_schluessel,strasse_name,strasse_schluessel,hausnummer,hausnummer_zusatz,postleitzahl,art,stellplaetze,gebuehren,ueberdacht) FROM STDIN DELIMITER ',' CSV HEADER;"
psql -c "UPDATE all_parking_rostock SET ogc_fid=id, geom=ST_TRANSFORM(ST_SetSRID(ST_MakePoint(org_lon, org_lat),4326),3857)"
