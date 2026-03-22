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

#set the ip address
server_address=$(hostname -I)

#EOF
