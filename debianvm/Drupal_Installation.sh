#!/bin/bash

sudo apt update

echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
curl -fsSL  https://packages.sury.org/php/apt.gpg| sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg

sudo apt install nano wget curl apache2 mariadb-server mariadb-client

sudo apt install php libapache2-mod-php php-{fpm,cli,mysql,zip,gd,intl,mbstring,curl,xml,soap,tidy,bcmath,xmlrpc} 

sudo a2enmod rewrite

sudo systemctl restart apache2

sudo systemctl enable --now mariadb

mysql --user=root -p <<_EOF_
CREATE USER drupal@localhost IDENTIFIED BY "StrongDBPassw0rd";
GRANT ALL ON drupal.* TO drupal@localhost IDENTIFIED BY "StrongDBPassw0rd";
FLUSH PRIVILEGES;
_EOF_

DRUPAL_VERSION="7.54"
wget https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz

tar xvf drupal-${DRUPAL_VERSION}.tar.gz

sudo mv drupal-${DRUPAL_VERSION} /var/www/html/drupal

sudo chown -R www-data:www-data  /var/www/html/drupal

sudo a2dissite 000-default.conf
sudo systemctl restart apache

echo "<VirtualHost *:80>
    ServerAdmin
    DocumentRoot /var/www/html/drupal
    ServerName drupal.local
    ServerAlias www.drupal.local
    <Directory /var/www/html/drupal/>
        Options FollowSymlinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" > /etc/apache2/sites-available/drupal.conf

sudo ln -s /etc/apache2/sites-available/drupal.conf /etc/apache2/sites-enabled/drupal.conf

sudo systemctl restart apache2

sudo mv /etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/000-default.conf.bak
sudo systemctl restart apache2