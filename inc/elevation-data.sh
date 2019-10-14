#! /bin/bash

BASEDIR="${BASEDIR:-/vagrant}"
FILEDIR=${BASEDIR}/files
OSM_EXTRACT="${OSM_EXTRACT:-${BASEDIR}/data.osm.pbf}"

cd /home/maposmatic

# read SRTM 90m zone name -> area mapping table
echo "Importing SRTM zone database"
sudo -u maposmatic psql gis < "${FILEDIR}/database/db_dumps/srtm_zones.sql" > /dev/null

mkdir -p elevation-data
cd elevation-data

echo "Downloading SRTM archive files"

mkdir -p srtm-data
cd srtm-data

mkdir -p $CACHEDIR/srtm-data

# extract bounding box data in bash array format
bbox=$(cat /home/maposmatic/bounds/bbox.bash)

# create actaul bounding box bash array
eval b=$bbox

# create bounding box polygon WKT string
polygon="POLYGON((${b[1]} ${b[0]}, ${b[1]} ${b[2]}, ${b[3]} ${b[2]}, ${b[3]} ${b[0]}, ${b[1]} ${b[0]}))"
echo "Bounding box: ${polygon} for ${OSM_EXTRACT}"

# now download all zones the import bounding box overlaps with
for zone in $(psql gis --tuples-only --command="select zone from srtm_zones where ST_INTERSECTS(way, ST_GeomFromText('$polygon', 4326))")
do
    CACHEFILE=$CACHEDIR/srtm-data/$zone.zip
    SRTM_URL=http://viewfinderpanoramas.org/dem3/$zone.zip
    if ! test -f $CACHEFILE
    then
	echo "  downloading zone $zone"
	wget -q -O $CACHEFILE $SRTM_URL
    fi
    unzip -q $CACHEFILE
done

cd ..




echo "SRTM hillshading for PisteMap"

mkdir -p srtm
cd srtm

if [ "$SUDO_USER" != "travis" ]; then
  for file in $(find /home/maposmatic/elevation-data/srtm-data/ -name "*.hgt" | sort)
  do
      base=$(basename $file .hgt)
      echo "  processing $base"
      gdal_translate -q -of GTiff -co "TILED=YES" -a_srs "+proj=latlong" $file ${base}_adapted.tif

      gdalwarp -q -multi -of GTiff -co "TILED=YES" -srcnodata 32767 -t_srs "+proj=merc +ellps=sphere +R=6378137 +a=6378137 +units=m" -rcs -order 3 -tr 30 30 -multi ${base}_adapted.tif ${base}_warped.tif

      gdaldem hillshade -q ${base}_warped.tif ${base}_hillshade.tif
  done
else
  for file in $(find /home/maposmatic/elevation-data/srtm-data/ -name "*N{42..43}E00{6..7}*.hgt" | sort)
  do
      base=$(basename $file .hgt)
      echo "  processing $base"
      gdal_translate -q -of GTiff -co "TILED=YES" -a_srs "+proj=latlong" $file ${base}_adapted.tif

      gdalwarp -q -multi -of GTiff -co "TILED=YES" -srcnodata 32767 -t_srs "+proj=merc +ellps=sphere +R=6378137 +a=6378137 +units=m" -rcs -order 3 -tr 30 30 -multi ${base}_adapted.tif ${base}_warped.tif

      gdaldem hillshade -q ${base}_warped.tif ${base}_hillshade.tif
  done
fi

cd ..




echo "DEM data for OpenTopoMap"
mkdir -p dem
cd dem

# file taken from OpenTopoMap repository, which may not be installed at this point yet
cp "${FILEDIR}/relief_color_text_file.txt" .

if [ "$SUDO_USER" != "travis" ]; then
  # fill empty spaces
  for file in $(find /home/maposmatic/elevation-data/srtm-data -name "*.hgt" | sort)
  do
    echo "  processing "$(basename $file .hgt)
    gdal_fillnodata.py -q $file $(basename $file).tif
  done
else
  for file in $(find /home/maposmatic/elevation-data/srtm-data -name "*N{42..43}E00{6..7}*.hgt" | sort)
  do
    echo "  processing "$(basename $file .hgt)
    gdal_fillnodata.py -q $file $(basename $file).tif
  done
fi

# merge all elevation data into one single large tiled file
if [ "$SUDO_USER" != "travis" ]; then
  gdal_merge.py -n 32767 -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW -co PREDICTOR=2 -o raw.tif *.hgt.tif -q
else
  gdal_merge.py -n 32767 -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW -co PREDICTOR=2 -o raw.tif N{42..43}E00{6..7}*.hgt.tif -q
fi

ln -s raw.tif dem-srtm.tiff
ln -s raw.tif dem_srtm.tiff

# convert to google mercator projection
interpolation=cubicspline
for r in 90 500 1000 5000
do
  gdalwarp -co BIGTIFF=YES -co TILED=YES -co COMPRESS=LZW -co PREDICTOR=2 -t_srs "+proj=merc +ellps=sphere +R=6378137 +a=6378137 +units=m" -r $interpolation -tr $r $r raw.tif warp-$r.tif -q
  interpolation=bilinear
done

# create colored reliefs for low zoom levels
gdaldem color-relief -co COMPRESS=LZW -co PREDICTOR=2 -alpha warp-5000.tif relief_color_text_file.txt relief-5000.tif -q
gdaldem color-relief -co COMPRESS=LZW -co PREDICTOR=2 -alpha warp-500.tif  relief_color_text_file.txt relief-500.tif -q

# create hillshading 
gdaldem hillshade -z 7 -compute_edges -co COMPRESS=JPEG warp-5000.tif hillshade-5000.tif -q
gdaldem hillshade -z 7 -compute_edges -co BIGTIFF=YES -co TILED=YES -co COMPRESS=JPEG warp-1000.tif hillshade-1000.tif -q
gdaldem hillshade -z 4 -compute_edges -co BIGTIFF=YES -co TILED=YES -co COMPRESS=JPEG warp-500.tif hillshade-500.tif -q
gdaldem hillshade -z 7 -combined -compute_edges -co compress=lzw -co predictor=2 -co bigtiff=yes warp-90.tif hillshade-90.tif -q
# TODO: not used? gdal_translate -co compress=JPEG -co bigtiff=yes -co tiled=yes hillshade-90.tif hillshade-90-jpeg.tif -q

# set up countours database and table schema
sudo -u maposmatic psql --quiet gis < "${FILEDIR}/database/db_dumps/contours_schema.sql"

# create contours shapefile and imports its data into the database
gdal_contour -i 10 -a ele warp-90.tif . -q
shp2pgsql -a -g way -s 3857 contour.shp contours | psql --quiet contours 

cd ..

