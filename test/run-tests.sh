#! /bin/bash

PROJECT="/home/maposmatic"
CONFIG="$PROJECT/.ocitysmap.conf"

LAYOUT="single_page_index_side"
ORIENTATION="landscape"

if [ "$SUDO_USER" != "travis" ]; then
  BBOX="52.0100,8.5122 52.0300,8.5432"              # Bielefeld
else
  BBOX="43.7247599,7.4090279,43.7519311,7.4398704"  # Monaco
fi

PAPER="Din A4"
THUMB_WIDTH="400"

BASE_FOR_OVERLAY="CartoOsmBW"
PREVIEW_DIR=/home/maposmatic/maposmatic/www/static/img/

# PYTHON="python"
PYTHON="python3"

if test $# -gt 0
then
  STYLES=""
  OVERLAYS=""
  while [ $1 ] ; do
    if ( echo $1 | egrep -q '\s*#' ); then
      echo "Ignoring $1"
      shift
      continue
    elif ( echo $1 | grep -qi Overlay); then
      OVERLAYS="$OVERLAYS $1"
    else
      STYLES="$STYLES $1"
    fi
    shift
  done
else
  STYLES=$(grep name: $CONFIG | grep -v '#' | grep -vi 'Overlay' | sed -e 's/name://g' | sort)
  OVERLAYS=$(grep name: $CONFIG | grep -v '#' | grep -i Overlay | sed -e 's/name://g' | sort)
  rm -rf test-* thumbnails/test-*
fi

for style in $STYLES
do
  echo "Testing '$style' style"
  rm -f test-base-$style*
  for format in png pdf svgz
  do
    base=test-base-$style-$format
    printf "... %-4s " $format
    echo "ocitysmap --config=$CONFIG --bounding-box=$BBOX --title='Test $style ($format)' --format=$format --prefix=$base --language=de_DE.utf8 --layout=$LAYOUT --orientation=$ORIENTATION --paper-format='$PAPER' --style=$style" > $base.sh
    chmod a+x $base.sh
    /usr/bin/time -q -f "%E" -o $base.time ./$base.sh > $base.log 2> $base.err
    cat $base.time
  done
  base=test-base-$style-multi
  printf "... %-4s " mpdf
  echo "ocitysmap --config=$CONFIG --bounding-box=$BBOX --title='Test $style (multi)' --format=pdf --prefix=$base --language=de_DE.utf8 --layout=multi_page --orientation=portrait --paper-format='Din A4' --style=$style" > $base.sh
  chmod a+x $base.sh
  /usr/bin/time -q -f "%E" -o $base.time ./$base.sh > $base.log 2> $base.err
  cat $base.time
  convert test-base-$style-png.png test-base-$style-jpg.jpg
  convert -thumbnail $THUMB_WIDTH test-base-$style-png.png thumbnails/test-base-$style-png.jpg
  if test -n "$PREVIEW_DIR"
  then
    cp thumbnails/test-base-$style-png.jpg $PREVIEW_DIR/style/$style.jpg
  fi

  php index.php > index.html
  ( cd thumbnails && php index.php > index.html )
done

for overlay in $OVERLAYS
do
  echo "Testing '$overlay' overlay"
  rm -f test-overlay-$overlay*
  for format in png pdf svgz
  do
    base=test-overlay-$overlay-$format
    printf "... %-4s " $format
    echo "ocitysmap --config=$CONFIG --bounding-box=$BBOX --title='Test $overlay ($format)' --format=$format --prefix=$base --language=de_DE.utf8 --layout=$LAYOUT --orientation=$ORIENTATION --paper-format='$PAPER' --style='$BASE_FOR_OVERLAY' --overlay=$overlay" > $base.sh
    chmod a+x $base.sh
    /usr/bin/time -q -f "%E" -o $base.time ./$base.sh > $base.log 2> $base.err
    cat $base.time
  done
  base=test-overlay-$overlay-multi
  printf "... %-4s " mpdf
  echo "ocitysmap --config=$CONFIG --bounding-box=$BBOX --title='Test $overlay (multi)' --format=pdf --prefix=$base --language=de_DE.utf8 --layout=multi_page --orientation=portrait --paper-format='Din A4' --style='$BASE_FOR_OVERLAY' --overlay=$overlay" > $base.sh
  chmod a+x $base.sh
  /usr/bin/time -q -f "%E" -o $base.time ./$base.sh > $base.log 2> $base.err
  cat $base.time
  convert test-overlay-$overlay-png.png test-overlay-$overlay-jpg.jpg
  convert -thumbnail $THUMB_WIDTH test-overlay-$overlay-png.png thumbnails/test-overlay-$overlay-png.jpg
  if test -n "$PREVIEW_DIR"
  then
    cp thumbnails/test-overlay-$overlay-png.jpg $PREVIEW_DIR/overlay/$overlay.jpg
  fi

  php index.php > index.html
  ( cd thumbnails && php index.php > index.html )
done
