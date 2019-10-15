#----------------------------------------------------
#
# Set up PostgreSQL and PostGIS 
#
#----------------------------------------------------

# add "gis" database users
sudo --user=postgres createuser --superuser --no-createdb --no-createrole maposmatic
sudo -u postgres createuser -g maposmatic root

if [ "$SUDO_USER" != "travis" ]; then
  sudo -u postgres createuser -g maposmatic vagrant
else
  sudo -u postgres createuser -g maposmatic travis
fi


# create database for osm2pgsql import 
sudo --user=postgres createdb --encoding=UTF8 --locale=en_US.UTF-8 --template=template0 --owner=maposmatic gis

# set up PostGIS for osm2pgsql database
sudo --user=postgres psql --dbname=gis --command="CREATE EXTENSION postgis"
sudo --user=postgres psql --dbname=gis --command="ALTER TABLE geometry_columns OWNER TO maposmatic"
sudo --user=postgres psql --dbname=gis --command="ALTER TABLE spatial_ref_sys OWNER TO maposmatic"

# enable hstore extension
sudo --user=postgres psql --dbname=gis --command="CREATE EXTENSION hstore"

# set up maposmatic admin table
sudo --user=maposmatic psql --dbname=gis --command="CREATE TABLE maposmatic_admin (last_update timestamp)"
sudo --user=maposmatic psql --dbname=gis --command="INSERT INTO maposmatic_admin VALUES ('1970-01-01 00:00:00')"

# create database for maposmatic
sudo --user=postgres createdb --encoding=UTF8 --locale=en_US.UTF-8 --template=template0 --owner=maposmatic maposmatic

# set password for gis database user
sudo --user=maposmatic psql --dbname=postgres --command="ALTER USER maposmatic WITH PASSWORD 'secret';"

