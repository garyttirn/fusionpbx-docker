#!/bin/sh

#Custom install based on https://github.com/fusionpbx/fusionpbx-install.sh/blob/master/debian/install.sh for docker container

#move to script directory so all relative paths work
cd "$(dirname "$0")"

#includes
. ./resources/config.sh
. ./resources/colors.sh
. ./resources/environment.sh

#disable vi visual mode
echo "set mouse-=a" >> ~/.vimrc

# Install development tools

apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    ghostscript libtiff5-dev libtiff-tools autoconf automake devscripts g++ libncurses5-dev \
    libtool-bin make libjpeg-dev pkg-config flac  libgdbm-dev libdb-dev gettext sudo equivs dpkg-dev libpq-dev libtinfo6 \
    liblua5.3-dev libtiff5-dev libperl-dev libcurl4-openssl-dev libsqlite3-dev libpcre2-dev libpcre2-8-0\
    devscripts libspeexdsp-dev libspeex-dev libldns-dev libedit-dev libopus-dev libmemcached-dev \
    libshout3-dev libmpg123-dev libmp3lame-dev yasm nasm libsndfile1-dev libuv1-dev libvpx-dev \
    libavformat-dev libswscale-dev libvlc-dev sox libsox-fmt-all sqlite3 zip unzip cmake uuid-dev \
    e2fsprogs e2fsprogs-l10n libcommon-sense-perl libjson-perl libjson-xs-perl \
    libpq-dev libpq5 libss2 libtypes-serialiser-perl logrotate logsave python3-distutils-extra plocate openssl \
    bsd-mailx exim4-base exim4-config exim4-daemon-light libfile-fcntllock-perl at \
    liblockfile-bin liblockfile1 libnsl2 libapache2-mod-log-sql-ssl libfreetype6-dev git-buildpackage doxygen yasm nasm gdb \
    build-essential automake autoconf 'libtool-bin|libtool' uuid-dev zlib1g-dev 'libjpeg8-dev|libjpeg62-turbo-dev' libncurses5-dev \
    libssl-dev libcurl4-openssl-dev libldns-dev libedit-dev libspeexdsp-dev libspeexdsp-dev libsqlite3-dev perl libgdbm-dev libdb-dev bison \
    libvlc-dev libvlccore-dev pkg-config ccache libpng-dev libvpx-dev libyuv-dev libopenal-dev libcodec2-dev \
    libmongoc-dev libsoundtouch-dev libmagickcore-dev libopus-dev libsndfile-dev libopencv-dev \
    libavformat-dev libx264-dev erlang-dev libldap2-dev libmemcached-dev libperl-dev portaudio19-dev \
    libsnmp-dev libyaml-dev libpq-dev libvlc-dev memcached libshout3-dev libvpx-dev libmpg123-dev libmp3lame-dev \
    libpcre3 && rm -rf /var/lib/apt/lists/*

# Packages to add for trixie support
# libext2fs2t64 libicu76

#sngrep
resources/sngrep.sh

#PHP
resources/php.sh

#NGINX web server
resources/nginx.sh

#FusionPBX
resources/fusionpbx.sh

#Optional Applications
resources/applications.sh

#Postgresql Database
resources/docker-postgresql.sh

#FreeSWITCH
resources/switch.sh

#Cleanup
apt-get purge -y \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    cmake \
    yasm \
    nasm \
    gnupg \
    logrotate \
    *-dev \
    && apt-get autoremove -y --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf \
    /usr/share/doc/* \
    /usr/share/man/* \
    /usr/src/freeswitch* \
    /usr/src/sofia* \
    /usr/src/libks \
    /usr/src/spandsp \
    /usr/src/*.zip

#Finalize setup on first run if no database
#EOF
