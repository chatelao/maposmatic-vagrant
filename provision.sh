#! /bin/bash

# For some strange reason I don't understand yet Vagrant
# seems to write "exit" to the provisioning scripts
# stdin stream. As this may confuse tools that optionally
# read from stdin (genenrate-xml.py in this case) we're
# draining stdin here as the first thing before doing
# anything else
if [ "$SUDO_USER" != "travis" ]; then
  if ! test -t 0
  then
     cat > /dev/null
  fi
fi

#----------------------------------------------------
#
# putting some often used constants into variables
#
#----------------------------------------------------

echo "SUDO_USER: $SUDO_USER"
echo "USER: $USER"

if [ "$SUDO_USER" != "travis" ]; then
  BASEDIR=/vagrant
else
  BASEDIR=$(dirname $(readlink -f $0))
fi
echo "Starting from: $BASEDIR"

FILEDIR=${BASEDIR}/files
INCDIR=${BASEDIR}/inc

if touch ${BASEDIR}/can_write_here
then
	CACHEDIR=${BASEDIR}/cache
	rm ${BASEDIR}/can_write_here
else
	mkdir -p /home/cache
	chmod a+rwx /home/cache
	CACHEDIR=/home/cache
fi

mkdir -p $CACHEDIR

#----------------------------------------------------
#
# check for an OSM PBF extract to import
#
# if there are more than one: take the first one found
# if there are none: exit
#
#----------------------------------------------------

export OSM_EXTRACT=$(ls ${BASEDIR}/*.pbf | head -1)

if test -f "$OSM_EXTRACT"
then
	echo "Using $OSM_EXTRACT for OSM data import"
else
	echo "No OSM .pbf data file found for import!"
	exit 3
fi



#----------------------------------------------------
#
# Vagrant/Virtualbox environment preparations
# (not really Ocitysmap specific yet)
#
#----------------------------------------------------

# override language settings
locale-gen en_US.UTF-8
localedef --force --inputfile=en_US --charmap=UTF-8 en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ADDRESS=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_IDENTIFICATION=en_US.UTF-8
export LC_MEASUREMENT=en_US.UTF-8
export LC_MESSAGE=en_US.UTF-8
export LC_MONETARY=en_US.UTF-8
export LC_NAME=en_US.UTF-8
export LC_NUMERIC=en_US.UTF-8
export LC_PAPER=en_US.UTF-8
export LC_TELEPHONE=en_US.UTF-8
export LC_TIME=en_US.UTF-8

# silence curl and wget progress reports
# as these just flood the vagrant output in an unreadable way
echo "--silent" > /root/.curlrc
echo "quiet = on" > /root/.wgetrc

# pre-seed compiler cache
if test -d $CACHEDIR/.ccache/
then
    cp -rn $CACHEDIR/.ccache/ ~/
else
    mkdir -p ~/.ccache
fi


# installing apt, pip and npm packages

. $INCDIR/install-packages.sh

# initial git configuration
. $INCDIR/git-setup.sh

# add "maposmatic" system user that will own the database and all locally installed stuff
useradd --create-home maposmatic

# add host entry for gis-db
sed -ie 's/localhost/localhost gis-db/g' /etc/hosts

# no longer needed starting with yakkety
# . $INCDIR/mapnik-from-source.sh

banner "db setup"
. $INCDIR/database-setup.sh

#
# Exclude "places" on travis due to diskspace restrictions
#
if [ "$SUDO_USER" != "travis" ]; then
  banner "places db"
  . $INCDIR/places-database.sh
fi

banner "db l10n"
. $INCDIR/mapnik-german-l10n.sh

banner "building osgende"
. $INCDIR/osgende.sh

# banner "building osm2pgsql"
# . $INCDIR/osm2pgsql-build.sh

banner "building phyghtmap" # needed by OpenTopoMap
. $INCDIR/phyghtmap.sh
   
banner "db import" 
. $INCDIR/osm2pgsql-import.sh

banner "get bounds"
. $INCDIR/data-bounds.sh

banner "DEM setup"
. $INCDIR/elevation-data.sh

banner "renderer setup"
. $INCDIR/ocitysmap.sh

banner "locales"
. $INCDIR/locales.sh

#----------------------------------------------------
#
# Set up various stylesheets 
#
#----------------------------------------------------

banner "shapefiles"
. $INCDIR/get-shapefiles.sh
cp ${FILEDIR}/shapefile-update.* /etc/systemd/system
systemctl daemon-reload

mkdir /home/maposmatic/styles

for style in ${INCDIR}/styles/*.sh
do
  banner $(basename $style .sh)" style"
  . $style
done

for overlay in ${INCDIR}/overlays/*.sh
do
  banner $(basename $overlay .sh)" overlay"
  . $overlay
done

#----------------------------------------------------
#
# Postprocess all generated style sheets
#
#----------------------------------------------------

banner "postprocessing styles"

. $INCDIR/ocitysmap-conf.sh

# cd /home/maposmatic/styles
# find . -name osm.xml | xargs \
#    sed -i -e's/background-color="#......"/background-color="#FFFFFF"/g'

#----------------------------------------------------
#
# Setting up Django fronted
#
#----------------------------------------------------

banner "django frontend"

. $INCDIR/apache-global-config.sh
. $INCDIR/maposmatic-frontend.sh


#----------------------------------------------------
#
# Setting up "Umgebungsplaene" alternative frontend
#
#----------------------------------------------------

banner "umgebungsplaene"

. $INCDIR/umgebungsplaene.sh


#----------------------------------------------------
#
# tests
#
#-----------------------------------------------------

if [ $USER != "travis" ]; then
   banner "running tests"

   cd ${BASEDIR}/test
   chmod a+w .
   rm -f test-* thumbnails/test-*
   ./run-tests.sh
fi

#----------------------------------------------------
#
# cleanup
#
#-----------------------------------------------------

banner "cleanup"

# some necessary security tweaks
. $INCDIR/security-quirks.sh

# write back compiler cache
cp -rn ~/.ccache $CACHEDIR
