#----------------------------------------------------
#
# Install all required packages 
#
#----------------------------------------------------

# uncomment this when using an old Ubuntu release no longer supported
# sed -i -e's/archive/old-releases/g' /etc/apt/sources.list


# we don't have "banner" installed yet at this point
echo "   ##    #####    #####          #####     ##     ####   #    #    ##     #### "
echo "  #  #   #    #     #            #    #   #  #   #    #  #   #    #  #   #    #"
echo " #    #  #    #     #            #    #  #    #  #       ####    #    #  #     "
echo " ######  #####      #            #####   ######  #       #  #    ######  #  ###"
echo " #    #  #          #            #       #    #  #    #  #   #   #    #  #    #"
echo " #    #  #          #            #       #    #   ####   #    #  #    #   #### "

# prevent configuration dialogs from popping up, we want fully automatic install
export DEBIAN_FRONTEND=noninteractive

# bring apt package database up to date
apt-get update --quiet=2

# install needed extra deb pacakges
apt-get install --quiet=2 --assume-yes \
    apache2 \
    asciidoctor \
    cabextract \
    cmake \
    coderay \
    curl \
    emacs \
    fonts-arkpandora \
    fonts-droid-fallback \
    fonts-khmeros \
    fonts-noto \
    fonts-noto-color-emoji \
    fonts-sil-padauk \
    fonts-sipa-arundina \
    fonts-taml-tscu \
    g++ \
    gir1.2-pango-1.0 \
    gir1.2-rsvg-2.0 \
    ccache \
    gdal-bin \
    gettext \
    git \
    imagemagick \
    libapache2-mod-php \
    libapache2-mod-wsgi-py3 \
    libboost-python-dev \
    libbz2-dev \
    libgdal-dev \
    libkakasi2-dev \
    liblua5.3-dev \
    libmapnik3.0 \
    libmapnik-dev \
    libosmium2-dev \
    libpython3-dev \
    libutf8proc-dev \
    mapnik-utils \
    mc \
    npm \
    osm2pgsql \
    osmium-tool \
    osmosis \
    pandoc \
    php-cli \
    php-http-request2 \
    php7.2-xml \
    pngquant \
    poedit \
    postgis \
    postgresql \
    postgresql-contrib \
    postgresql-server-dev-all \
    python-gdal \
    python-mapnik \
    python-setuptools \
    python-matplotlib \
    python-beautifulsoup \
    python-numpy \
    python3-django \
    python3-future \
    python3-feedparser \
    python3-fiona \
    python3-gdal \
    python3-gi-cairo \
    python3-gpxpy \
    python3-lxml \
    python3-mapnik \
    python3-pip \
    python3-pil \
    python3-psycopg2 \
    python3-shapely \
    python3-slugify \
    python3-urllib3 \
    subversion \
    sysvbanner \
    time \
    transifex-client \
    tree \
    ttf-dejavu \
    ttf-unifont \
    unifont \
    unifont-bin \
    unzip \
    wkhtmltopdf \
    > /dev/null

banner "python packages"
pip3 install --ignore-installed \
     colour \
     django-maintenance-mode \
     fastnumbers \
     geoalchemy2 \
     geopy \
     natsort \
     osmium \
     pillow \
     pluginbase \
     pycairo \
     pyproj \
     qrcode \
     "sqlalchemy==1.2" \
     "sqlalchemy-utils==0.35" \
     utm \
     > /dev/null

banner "ruby packages"
gem install --pre asciidoctor-pdf > /dev/null


# install extra npm packages
banner "npm packages"
(cd /usr/local/bin; ln -s /usr/bin/nodejs node)
npm config set loglevel warn

npm install -g carto

# this package is currently broken in Ubuntu, see e.g. 
# https://bugs.launchpad.net/ubuntu/+source/msttcorefonts/+bug/1607535
# so we need to use the working upstream Debian package

banner "ms fonts"
if ! dpkg -i /vagrant/files/ttf-mscorefonts-installer_3.6_all.deb > /dev/null 2>/tmp/ms-fonts.log
then
	cat 1>&2 /tmp/ms-fonts.log
fi



