#!/bin/sh

#Execute for new installs via docker compose exec fusionpbx /bin/bash to create database etc.
#Contains eelevant parts of /usr/src/fusionpbx-install.sh/debian/resources/postgresql.sh and #/usr/src/fusionpbx-install.sh/debian/resources/finish.sh

#move to script directory so all relative paths work
cd "$(dirname "$0")"

#includes
. ./config.sh
. ./colors.sh
. ./environment.sh

#set the ip address
server_address=$(hostname -I)

#database details

#generate a random password
password=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64 | sed 's/[=\+//]//g')
database_username=fusionpbx
database_password=$password

#allow the script to use the new password
export PGPASSWORD=$password

if sudo -E  -u postgres psql fusionpbx -c '\q' 2>&1; then
   echo "Database fusionpbx exists, not creating"
   return 0;
fi

echo "Create the database and users\n"

#move to /tmp to prevent a red herring error when running sudo with psql
cwd=/usr/src/fusionpbx-install.sh/debian/resources
cd /tmp

#reload the config
sudo -E  -u postgres psql -c "SELECT pg_reload_conf();"

#set client encoding
sudo -E  -u postgres psql -c "SET client_encoding = 'UTF8';";

#add the database users and databases
sudo -E  -u postgres psql -c "CREATE DATABASE fusionpbx;";

#add the users and grant permissions
sudo -E  -u postgres psql -c "CREATE ROLE fusionpbx WITH SUPERUSER LOGIN PASSWORD '$password';"
#sudo -E  -u postgres psql -c "CREATE ROLE freeswitch WITH SUPERUSER LOGIN PASSWORD '$password';"
sudo -E  -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE fusionpbx to fusionpbx;"

#in case DB was dropped on purpose and needs recreating
sudo -E  -u postgres psql -c "ALTER USER fusionpbx WITH PASSWORD '$password';"

cd $cwd

#add the config.conf
mkdir -p /etc/fusionpbx
cp /usr/src/fusionpbx-install.sh/debian/resources/fusionpbx/config.conf /etc/fusionpbx
sed -i /etc/fusionpbx/config.conf -e s:"{database_host}:$database_host:"
sed -i /etc/fusionpbx/config.conf -e s:"{database_name}:$database_name:"
sed -i /etc/fusionpbx/config.conf -e s:"{database_username}:$database_username:"
sed -i /etc/fusionpbx/config.conf -e s:"{database_password}:$database_password:"

#add the database schema
cd /var/www/fusionpbx && /usr/bin/php /var/www/fusionpbx/core/upgrade/upgrade.php --schema

#get the server hostname
if [ .$domain_name = .'hostname' ]; then
	domain_name=$(hostname -f)
fi

#get the ip address
if [ .$domain_name = .'ip_address' ]; then
	domain_name=$(hostname -I | cut -d ' ' -f1)
fi

#get the domain_uuid
domain_uuid=$(/usr/bin/php /var/www/fusionpbx/resources/uuid.php);

#move to /tmp to prevent a red herring error when running sudo with psql
cwd=$(pwd)
cd /tmp

#add the domain name
sudo -E  -u postgres psql --host=$database_host --port=$database_port --username=$database_username -c "insert into v_domains (domain_uuid, domain_name, domain_enabled) values('$domain_uuid', '$domain_name', 'true');"

#run app defaults
cd /var/www/fusionpbx && /usr/bin/php /var/www/fusionpbx/core/upgrade/upgrade.php --defaults

#add the user
user_uuid=$(/usr/bin/php /var/www/fusionpbx/resources/uuid.php);
user_salt=$(/usr/bin/php /var/www/fusionpbx/resources/uuid.php);
user_name=$system_username
if [ .$system_password = .'random' ]; then
	user_password=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64 | sed 's/[=\+//]//g')
else
	user_password=$system_password
fi
password_hash=$(/usr/bin/php -r "echo md5('$user_salt$user_password');");
sudo -E  -u postgres psql --host=$database_host --port=$database_port --username=$database_username -t -c "insert into v_users (user_uuid, domain_uuid, username, password, salt, user_enabled) values('$user_uuid', '$domain_uuid', '$user_name', '$password_hash', '$user_salt', 'true');"

#get the superadmin group_uuid
group_uuid=$(sudo -E  -u postgres psql --host=$database_host --port=$database_port --username=$database_username -qtAX -c "select group_uuid from v_groups where group_name = 'superadmin';");

#add the user to the group
user_group_uuid=$(/usr/bin/php /var/www/fusionpbx/resources/uuid.php);
group_name=superadmin
#echo "insert into v_user_groups (user_group_uuid, domain_uuid, group_name, group_uuid, user_uuid) values('$user_group_uuid', '$domain_uuid', '$group_name', '$group_uuid', '$user_uuid');"
sudo -E  -u postgres psql --host=$database_host --port=$database_port --username=$database_username -c "insert into v_user_groups (user_group_uuid, domain_uuid, group_name, group_uuid, user_uuid) values('$user_group_uuid', '$domain_uuid', '$group_name', '$group_uuid', '$user_uuid');"

cd $cwd

#update xml_cdr url, user and password
xml_cdr_username=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64 | sed 's/[=\+//]//g')
xml_cdr_password=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64 | sed 's/[=\+//]//g')
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{v_http_protocol}:http:"
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{domain_name}:$database_host:"
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{v_project_path}::"
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{v_user}:$xml_cdr_username:"
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{v_pass}:$xml_cdr_password:"

#update application defaults
cd /var/www/fusionpbx && /usr/bin/php /var/www/fusionpbx/core/upgrade/upgrade.php --defaults

#update permissions
cd /var/www/fusionpbx && /usr/bin/php /var/www/fusionpbx/core/upgrade/upgrade.php --permissions

#make the /var/run directory and set the ownership
mkdir -p /var/run/fusionpbx
chown -R www-data:www-data /var/run/fusionpbx

#install the services
cd /var/www/fusionpbx && /usr/bin/php /var/www/fusionpbx/core/upgrade/upgrade.php --services

#update file permissions
chmod 664 /etc/fusionpbx/config.conf

#Update nginx ports to 6080 and 6433
sed -i 's/listen \[::\].*/#listen \[::\]/g;s/listen 80;/listen 6080;/;s/listen 443 ssl;/listen 6443 ssl;/;' /etc/nginx/sites-available/fusionpbx

#restart nginx
/usr/sbin/service nginx start

#welcome message
echo ""
echo ""
verbose "Installation Notes. "
echo ""
echo "   Please save this information"
echo ""
echo "   Use a web browser to login."
echo "      domain name: https://$domain_name:6443"
echo "      username: $user_name"
echo "      password: $user_password"
echo ""
echo "   The domain name in the browser is used by default as part of the authentication."
echo "   If you need to login to a different domain then use username@domain."
echo "      username: $user_name@$domain_name";
echo ""
echo "   Additional information."
echo "      https://fusionpbx.com/members.php"
echo "      https://fusionpbx.com/training.php"
echo "      https://fusionpbx.com/support.php"
echo "      https://www.fusionpbx.com"
echo "      http://docs.fusionpbx.com"
echo ""

# pgpassword security and conflict avoidance
unset PGPASSWORD

#EOF
