#----------------------------------------------------
#
# Humanitarian "HOT" style
#
#----------------------------------------------------

cd /home/maposmatic/styles

git clone --quiet https://github.com/hholzgra/HDM-CartoCSS.git

cd HDM-CartoCSS

git checkout --quiet nohillshade

sed -e's|/ybon/Data/geo/shp/|/maposmatic/shapefiles/|g' \
    -e's|/ybon/Code/maps/hdm/|/maposmatic/styles/HDM-CartoCSS/|g' \
    -e's|http://data.openstreetmapdata.com/land-polygons-split-3857.zip|/home/maposmatic/shapefiles/land-polygons-split-3857/land_polygons.shp|g' \
    -e's|http://data.openstreetmapdata.com/simplified-land-polygons-complete-3857.zip|/home/maposmatic/shapefiles/simplified-land-polygons-complete-3857/simplified_land_polygons.shp|g' \
    -e"s|layer \~|tags->'layer' \~|g" \
    -e's|dbname: osm|dbname: gis|g' \
    -e'/host:/d' \
    -e'/user:/d' \
    -e'/password:/d' \
    < project.yml > project.mml

carto -q -a $(mapnik-config -v) project.mml > osm.xml

# -e's|user: hot|user: maposmatic|g' \


# cd DEM
# mkdir -p data
# ./fetch.sh 38,1,40,3 # TODO - this only fetches a small part of Germany
# ./hillshade.sh
# ./hillshade_to_vrt.sh
# ./merge_contour.sh

