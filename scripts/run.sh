#!/bin/sh

echo 'running script'

# sitename for subdomain available as $N, port as $P 
name="$N"
port="$P"

# set WP site URL

# set port in nginx
sed -i "s/NGINX_LISTEN_PORT/$port/g" /etc/nginx/nginx.conf


# add subdomain to hosts file
echo "127.0.0.1       $name.localhost" >> /etc/hosts

# TODO: if expected envs aren's set, show default nginx page with warning to try again

[ -f /run-pre.sh ] && /run-pre.sh

if [ ! -d /usr/html ] ; then
  echo "[i] Creating directories..."
  mkdir -p /usr/html
  echo "[i] Fixing permissions..."
  chown -R nginx:nginx /usr/html
else
  echo "[i] Fixing permissions..."
  chown -R nginx:nginx /usr/html
fi

chown -R nginx:www-data /usr/html

# start php-fpm
mkdir -p /usr/logs/php-fpm
php-fpm7


# start mysql and send to background
exec /usr/bin/mysqld --user=root &

# wait for mysql to be ready
while ! mysqladmin ping -h localhost --silent; do
    echo 'waiting for mysql to be available...'
    sleep 1
done

# add root@localhost user
/usr/bin/mysql < /mysql_user.sql

cd /usr/html
# setup WP
sudo -u nginx wp core config --dbhost=localhost --dbname=wordpress --dbuser=root --dbpass=banana
rm wp-config-sample.php

sudo -u nginx wp core install --url="http://$name.localhost:$port" --title='Welcome to Lokl' --admin_user=admin --admin_password=admin --admin_email=me@example.com

wp rewrite structure '/%postname%/'
wp option update blogdescription "Your fast, secure local WP environment"
wp post update 1 --post_content="Use this site as your starting point or import content from an existing site. <a href='/wp-admin'>View Dashboard</a>"
wp post update 1 --post_title="Getting started"

# activate default plugins
wp plugin activate static-html-output-plugin
wp plugin activate simplerstatic
# wp plugin activate auto-login


# start nginx
mkdir -p /usr/logs/nginx
mkdir -p /tmp/nginx
chown nginx /tmp/nginx
nginx
