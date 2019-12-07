#!/bin/bash
if [[ -f /home/vagrant/.provisioned ]] ; then
    echo "##############################"
    echo "#### System already setup ####"
    echo "##############################"
    exit
fi
echo "########################"
echo "# Starting Setup"

# Update
echo "## Updating..."
yum update -y &> /dev/null

echo "## Installing dependencies..."
yum install -y epel-release &> /dev/null
yum install -y nano git unzip avahi wget &> /dev/null
systemctl enable avahi-daemon.service &> /dev/null
systemctl start avahi-daemon.service

setenforce 0
sed -i "s/\SELINUX=enforcing/\SELINUX=disabled/g" /etc/selinux/config

# Install Nginx
echo "## Installing Nginx..."
yum install -y nginx &> /dev/null
mv /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html.bak
cp /var/www/boson.local/index.html /usr/share/nginx/html/index.html
chown nginx:nginx /usr/share/nginx/html/index.html
usermod -aG vagrant nginx
systemctl enable nginx.service &> /dev/null
setsebool -P httpd_can_network_connect 1
systemctl start nginx

# Install MySQL (MariaDB)
echo "## Installing MariaDB..."
yum install -y mariadb-server mariadb &> /dev/null
systemctl enable mariadb.service &> /dev/null
systemctl start mariadb

mysql --user=root <<_EOF_
  UPDATE mysql.user SET Password=PASSWORD('laserred') WHERE User='root';
  DELETE FROM mysql.user WHERE User='';
  DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
  DROP DATABASE IF EXISTS test;
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
  FLUSH PRIVILEGES;
_EOF_
echo "### DB login: root / laserred"

# Install PHP 7.3
echo "## Installing PHP 7.3 and modules..."
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm &> /dev/null
yum -y install epel-release yum-utils &> /dev/null
yum-config-manager --disable remi-php54 &> /dev/null
yum-config-manager --enable remi-php73 &> /dev/null
yum -y install php php-common php-cli php-fpm php-mysqlnd php-zip php-devel php-gd php-mcrypt php-mbstring php-xml php-pear php-bcmath php-json php-gd php-intl php-simplexml php-soap &> /dev/null
sed -i "s/;cgi.fix_pathinfo=1/\cgi.fix_pathinfo=0/g" /etc/php.ini
sed -i 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.owner = nobody/listen.owner = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.group = nobody/listen.group = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.mode = 0660/listen.mode = 0660/g' /etc/php-fpm.d/www.conf
sed -i 's/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g' /etc/php-fpm.d/www.conf
sed -i 's/;session.save_path = \"\/tmp\"/session.save_path = \"\/var\/lib\/php\/sessions\/\"/g' /etc/php.ini
chown -R nginx:nginx /var/lib/php/session
systemctl enable php-fpm.service &> /dev/null
systemctl start php-fpm
systemctl restart nginx

echo "## Installing phpMyAdmin..."
mkdir /var/www/phpmyadmin/
wget -qO /var/www/phpmyadmin/phpmyadmin.zip https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip
unzip /var/www/phpmyadmin/phpmyadmin.zip -d /var/www/phpmyadmin/ &> /dev/null
rm -f /var/www/phpmyadmin/phpmyadmin.zip
mv /var/www/phpmyadmin/phpMyAdmin* /var/www/phpmyadmin/htdocs/

echo "## Configuring phpMyAdmin..."
cp /var/www/phpmyadmin/htdocs/config.sample.inc.php /var/www/phpmyadmin/htdocs/config.inc.php
sed -i "s/\['AllowNoPassword'\] = false;/\['AllowNoPassword'\] = true;/g" /var/www/phpmyadmin/htdocs/config.inc.php
mv /tmp/phpmyadmin.conf /etc/nginx/conf.d/phpmyadmin.conf
systemctl restart nginx
echo "### phpMyAdmin available at http://$HOST_NAME.local:8080"

# Install Xdebug
echo "## Install Xdebug..."
pecl install xdebug &> /dev/null
echo "xdebug.remote_enable = 1" >> /etc/php.ini
echo "xdebug.remote_connect_back = 1" >> /etc/php.ini

# Composer Installation
echo "## Install Composer..."
curl -sS https://getcomposer.org/installer | php &> /dev/null
mv composer.phar /usr/bin/composer

touch /home/vagrant/.provisioned

# Post Up Message
if [ -z "$1" ]
	then
		echo "## Final installation instructions:"
		echo "### run 'vagrant ssh'"
		echo "### run 'cd /var/www/$HOST_NAME.local/htdocs'"
		echo "### run 'composer install'"
		echo "### When prompted, enter your API credentials"
fi
echo "### Go to http://$HOST_NAME.local/setup/ to finish installation."
echo "# Setup Complete"
echo "########################"