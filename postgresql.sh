#!/bin/sh

#move to script directory so all relative paths work
cd "$(dirname "$0")"

#includes
. ./config.sh
. ./colors.sh
. ./environment.sh

#send a message
echo "Install PostgreSQL"

#make sure keyrings directory exits
mkdir /etc/apt/keyrings

#postgres official repository
if [ ."$database_repo" = ."official" ]; then
	sh -c 'echo "deb [signed-by=/etc/apt/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
	wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/keyrings/pgdg.gpg
	chmod 644 /etc/apt/keyrings/pgdg.gpg
	apt-get update
	if [ ."$database_version" = ."latest" ]; then
           apt-get install -y sudo postgresql
        else
           apt-get install -y sudo postgresql-$database_version
        fi
fi

#replace scram-sha-256 with md5
sed -i /etc/postgresql/$database_version/main/pg_hba.conf -e '/^#/!s/scram-sha-256/md5/g'

/usr/sbin/service postgresql start
