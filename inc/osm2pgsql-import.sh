#----------------------------------------------------
#
# Import OSM data into database
#
#----------------------------------------------------

BASEDIR=${BASEDIR:-/vagrant}
FILEDIR=${BASEDIR}/files
OSM_EXTRACT="${OSM_EXTRACT:-${BASEDIR}/data.osm.pbf}"

cd /home/maposmatic

# get style file

if ! test -f hstore-only.style
then
  wget https://raw.githubusercontent.com/giggls/openstreetmap-carto-de/master/hstore-only.style
fi
if ! test -f openstreetmap-carto.lua
then
  wget https://raw.githubusercontent.com/giggls/openstreetmap-carto-de/master/openstreetmap-carto.lua
fi

# import data
sudo --user=maposmatic osm2pgsql \
     --create \
     --slim \
     --database=gis \
     --merc \
     --hstore-all \
     --cache=1000 \
     --number-processes=2 \
     --style=hstore-only.style \
     --tag-transform-script=openstreetmap-carto.lua \
     --prefix=planet_osm_hstore \
     $OSM_EXTRACT

# install views to provide expected table layouts from hstore-only bas tables

for dir in db_indexes db_functions db_views
do
  for sql in ${BASEDIR}/files/database/$dir/*.sql
  do
    sudo -u maposmatic psql gis < $sql
  done
done


# prepare for diff imports
OSMOSIS_DIFFIMPORT=/home/maposmatic/osmosis-diffimport
mkdir -p $OSMOSIS_DIFFIMPORT

REPLICATION_BASE_URL="$(osmium fileinfo -g 'header.option.osmosis_replication_base_url' "${OSM_EXTRACT}")"
if ! test -z "$REPLICATION_BASE_URL"
then
    echo -e "baseUrl=${REPLICATION_BASE_URL}\nmaxInterval=3600" > "${OSMOSIS_DIFFIMPORT}/configuration.txt"

    REPLICATION_SEQUENCE_NUMBER="$( printf "%09d" "$(osmium fileinfo -g 'header.option.osmosis_replication_sequence_number' "${OSM_EXTRACT}")" | sed ':a;s@\B[0-9]\{3\}\>@/&@;ta' )"

    cp ${FILEDIR}/systemd/osm2pgsql-update.* /etc/systemd/system
    chmod 644 /etc/systemd/system/osm2pgsql-update.*
    systemctl daemon-reload


    
    curl -s -L -o "${OSMOSIS_DIFFIMPORT}/state.txt" "${REPLICATION_BASE_URL}/${REPLICATION_SEQUENCE_NUMBER}.state.txt"

    # update import timestamp by osmosis state file
    . ${OSMOSIS_DIFFIMPORT}/state.txt # get timestamp from osmosis state.txt file
    sudo -u maposmatic psql gis -c "update maposmatic_admin set last_update='$timestamp'"

else
    # update import timestamp by osm file timestamp
    timestamp=$(stat --format='%Y' $OSM_EXTRACT)
    timestring=$(date --utc --date="@$timestamp" +"%FT%TZ")
    
    sudo --user=maposmatic psql \
	 --dbname=gis \
	 --command="UPDATE maposmatic_admin SET last_update = '$timestring'"
fi
