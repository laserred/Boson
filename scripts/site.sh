#!/bin/bash
TMP_ROOT=/var/www/vhosts/$HOST_NAME
TMP_MODE=developer # or production or developer

if [[ $HOST_NAME == "boson" || -f /etc/nginx/conf.d/$HOST_NAME.local.conf ]] ; then
    echo "#### Site already configured ####"
    exit
fi

echo "## Creating Site ##"

echo "Creating Nginx configs..."
echo "
upstream fastcgi_backend_$HOST_NAME {
   server   unix:/var/run/php-fpm.sock;
}
server {
   listen 80;
   server_name $HOST_NAME.local;
   set \$HOST_NAME $HOST_NAME;
   set \$MAGE_ROOT $TMP_ROOT;
   set \$MAGE_MODE $TMP_MODE;
   include template.d/magento2.conf;
}
" >> /etc/nginx/conf.d/$HOST_NAME.local.conf

echo "Creating database..."
mysql -uroot -plaserred -e "create database $HOST_NAME";

echo "Downloading Magento..."
su - vagrant -c "composer create-project --repository=https://repo.magento.com/ magento/project-community-edition /tmp/$HOST_NAME" &> /dev/null
# Download to a temp directory and then move as Virtualbox shares are
# too slow and causes composer to fail
echo "Copying files to webroot..."
mv /tmp/$HOST_NAME $TMP_ROOT

echo "Fix permissions..."
cd $TMP_ROOT
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +

echo "Installing Magento..."
su - vagrant -c "php $TMP_ROOT/bin/magento setup:install \
--base-url='http://$HOST_NAME.local' \
--db-host='localhost' \
--db-name='$HOST_NAME' \
--db-user='root' \
--db-password='laserred' \
--admin-firstname='admin' \
--admin-lastname='admin' \
--admin-email='webmaster@$HOST_NAME.local' \
--admin-user='admin' \
--admin-password='laserred1' \
--language='en_GB' \
--currency='GBP' \
--timezone='Europe/London' \
--use-rewrites='1' \
--backend-frontname='admin'" &> /dev/null
echo "### Magento URL: http://$HOST_NAME.local/admin"
echo "### Magento login: admin / laserred1"

systemctl restart nginx
systemctl restart php-fpm
systemctl restart avahi-daemon.service

echo "## Site Created ##"