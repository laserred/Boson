#!/bin/bash
if [[ -f /home/vagrant/.provisioned ]] ; then
  # Configure Magento
  if [[ ! -z "$MAGE_USER" ]] ; then
    echo "
    {
        \"http-basic\": {
            \"repo.magento.com\": {
                \"username\": \"$MAGE_USER\",
                \"password\": \"$MAGE_PASS\"
            }
        }
    }" > /home/vagrant/.config/composer/auth.json
  fi

  echo "## System already setup ##"
  exit
fi
echo "## Starting Setup ##"

# Update
echo "Updating..."
yum update -y &> /dev/null

echo "Installing dependencies..."
yum install -y epel-release &> /dev/null
yum install -y nano git unzip avahi wget &> /dev/null
systemctl enable avahi-daemon.service &> /dev/null
systemctl start avahi-daemon.service

setenforce 0
sed -i "s/\SELINUX=enforcing/\SELINUX=disabled/g" /etc/selinux/config

# Install Nginx
echo "Installing Nginx..."
yum install -y nginx &> /dev/null
mv /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html.bak
mv /tmp/templates/boson.default.html /usr/share/nginx/html/index.html
chown nginx:nginx /usr/share/nginx/html/index.html
usermod -aG vagrant nginx
systemctl enable nginx.service &> /dev/null
setsebool -P httpd_can_network_connect 1

## Move templates
mkdir /etc/nginx/template.d/
mv /tmp/templates/m2_nginx_template.conf /etc/nginx/template.d/magento2.conf

systemctl start nginx

# Install MySQL (MariaDB)
echo "Installing MariaDB..."
echo "# MariaDB 10.4 CentOS repository list - created 2019-12-09 19:16 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.4/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1" >> /etc/yum.repos.d/MariaDB.repo
yum update -y &> /dev/null
yum -y install MariaDB-server MariaDB-client &> /dev/null
systemctl enable mariadb.service &> /dev/null
systemctl start mariadb

mysql --user=root <<_EOF_
  ALTER USER 'root'@'localhost' IDENTIFIED BY 'laserred';
  DELETE FROM mysql.user WHERE User='';
  DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
  DROP DATABASE IF EXISTS test;
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
  FLUSH PRIVILEGES;
_EOF_
echo "### DB login: root / laserred"

# Install PHP
echo "Installing PHP $PHP_VER and modules..."
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm &> /dev/null
yum -y install epel-release yum-utils &> /dev/null
yum-config-manager --disable remi-php54 &> /dev/null
yum-config-manager --enable remi-php$PHP_VER &> /dev/null
yum -y install php php-common php-cli php-fpm php-mysqlnd php-zip php-devel php-gd php-mcrypt php-mbstring php-xml php-pear php-bcmath php-json php-gd php-intl php-simplexml php-soap &> /dev/null

# php.ini
sed -i "s/zlib.output_compression = Off/\zlib.output_compression = On/g" /etc/php.ini
sed -i "s/max_execution_time = 30/\max_execution_time = 1800/g" /etc/php.ini
sed -i "s/memory_limit = 128M/\memory_limit = 2G/g" /etc/php.ini
sed -i 's/;session.save_path = \"\/tmp\"/session.save_path = \"\/var\/lib\/php\/session\/\"/g' /etc/php.ini

# www.conf
sed -i 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.owner = nobody/listen.owner = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.group = nobody/listen.group = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.mode = 0660/listen.mode = 0660/g' /etc/php-fpm.d/www.conf
sed -i 's/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g' /etc/php-fpm.d/www.conf
sed -i 's/;env\[HOSTNAME\] = $HOSTNAME/\env\[HOSTNAME\] = $HOSTNAME/g' /etc/php-fpm.d/www.conf
sed -i 's/;env\[PATH\] = \/usr\/local\/bin:\/usr\/bin:\/bin/\env\[PATH\] = \/usr\/local\/bin:\/usr\/bin:\/bin/g' /etc/php-fpm.d/www.conf
sed -i 's/;env\[TMP\] = \/tmp/\env\[TMP\] =\/tmp/g' /etc/php-fpm.d/www.conf
sed -i 's/;env\[TMPDIR\] = \/tmp/\env\[TMPDIR\] = \/tmp/g' /etc/php-fpm.d/www.conf
sed -i 's/;env\[TEMP\] = \/tmp/\env\[TEMP\] = \/tmp/g' /etc/php-fpm.d/www.conf

chown -R nginx:nginx /var/lib/php/session
systemctl enable php-fpm.service &> /dev/null
systemctl start php-fpm
systemctl restart nginx

# Install phpMyAdmin
if [[ ! -d /var/www/vhosts/phpmyadmin/ ]] ; then
  echo "Installing phpMyAdmin..."
  mkdir /var/www/vhosts/phpmyadmin/
  wget -qO /var/www/vhosts/phpmyadmin/phpmyadmin.zip https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip
  unzip /var/www/vhosts/phpmyadmin/phpmyadmin.zip -d /var/www/vhosts/phpmyadmin/ &> /dev/null
  rm -f /var/www/vhosts/phpmyadmin/phpmyadmin.zip
  mv /var/www/vhosts/phpmyadmin/phpMyAdmin* /var/www/vhosts/phpmyadmin/htdocs/
fi
if [[ ! -f /etc/nginx/conf.d/phpmyadmin.conf ]] ; then
  echo "Configuring phpMyAdmin..."
  cp /var/www/vhosts/phpmyadmin/htdocs/config.sample.inc.php /var/www/vhosts/phpmyadmin/htdocs/config.inc.php
  sed -i "s/\['AllowNoPassword'\] = false;/\['AllowNoPassword'\] = true;/g" /var/www/vhosts/phpmyadmin/htdocs/config.inc.php
  mv /tmp/templates/phpmyadmin.conf /etc/nginx/conf.d/phpmyadmin.conf
  systemctl restart nginx
fi
echo "### phpMyAdmin available at http://$HOST_NAME.local:8080"

# Install Xdebug
echo "Install Xdebug..."
pecl install xdebug &> /dev/null
echo "xdebug.remote_enable = 1" >> /etc/php.ini
echo "xdebug.remote_connect_back = 1" >> /etc/php.ini

# Composer Installation
echo "Install Composer..."
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/bin --filename=composer &> /dev/null

# Configure Magento
mkdir -p /home/vagrant/.config/composer
echo "
{
    \"http-basic\": {
        \"repo.magento.com\": {
            \"username\": \"$MAGE_USER\",
            \"password\": \"$MAGE_PASS\"
        }
    }
}" > /home/vagrant/.config/composer/auth.json

# Install Magento Cloud CLI
curl -sS https://accounts.magento.cloud/cli/installer | php &> /dev/null

touch /home/vagrant/.provisioned

echo "## Setup Complete ##"
