#!/bin/bash

domain=CybersecurityNPE2023.local

date=$(date)
log_file=/var/log/install-drupal.log
web_dir=/var/www/$domain
sites_dir=/etc/apache2/sites-available
sites_file=$domain.conf
apache_logs=/var/log/apache2
mysql_pass="password"
drupal_download=https://ftp.drupal.org/files/projects/drupal-7.54.tar.gz
drupal_tar=/tmp/drupal.tar.gz

check_output () {
    if [ $1 -eq 0 ]; then
        echo "SUCCESS: $1 - $2 " >> $log_file
        return 0
    else
        echo "ERROR: $1 PLEASE CHECK LOGFILE - $2"
        echo "ERROR: $1 - $2" >> $log_file
        sudo sed -i "s/$mysql_pass/PasswordNotStoredInLogfile/g" $log_file
        sudo sed -i "s/$drupal_sql_pass/PasswordNotStoredInLogfile/g" $log_file
        exit
    fi
}

install_reqs () {
    sudo wget https://pastebin.com/raw/yBxPcvjM -O /home/osboxes/mysql_pubkey.asc &&
    gpg --dearmor mysql_pubkey.asc &&
    sudo cp mysql_pubkey.asc.gpg /etc/apt/trusted.gpg.d/ &&
    sudo apt update &&
    echo "mysql-server-5.7 mysql-server/root_password" $mysql_pass  | sudo debconf-set-selections
    echo "mysql-server-5.7 mysql-server/root_password_again password" $mysql_pass | sudo debconf-set-selections
    sudo DEBIAN_FRONTEND="noninteractive" apt-get install wget curl apache2 mysql-server php libapache2-mod-php php-{cli,fpm,json,common,mysql,zip,gd,intl,mbstring,curl,xml,pear,tidy,soap,bcmath,xmlrpc} -y
}

create_configs() {
    mkdir -v $web_dir &&
    touch $web_dir/index.html &&
    cat <<EOF > $web_dir/index.html
<meta http-equiv="refresh" content="1; URL=https://www.$domain/" />
EOF
    cat $web_dir/index.html
    touch $sites_dir/$sites_file &&
    cat <<EOF > $sites_dir/$sites_file
<VirtualHost *:80 *:443>
    ServerName $domain
    ServerAlias www.$domain 
    ServerAdmin help@$domain
    DocumentRoot $web_dir
    ErrorLog $apache_logs/error.log
    CustomLog $apache_logs/access.log combined
    <Directory $sites_dir>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
        RewriteEngine on
        RewriteBase /
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^(.*)$ index.php?q=\$1 [L,QSA]
   </Directory>
</VirtualHost>
EOF
    cat $sites_dir/$sites_file
}

finalize_apache() {
    a2ensite $domain &&
    a2dissite 000-default &&
    a2dismod mpm_event &&
    a2enmod mpm_prefork &&
    a2enmod php7.4 &&
    a2enmod rewrite &&
    apache2ctl configtest &&  
    systemctl reload apache2
}


config_mysql() {
    drupal_sql_pass="password"
    mysql -v << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$mysql_pass';
DELETE FROM mysql.user WHERE User='';
DROP USER IF EXISTS ''@'$(hostname)';
DROP DATABASE IF EXISTS test;
CREATE DATABASE drupal;
CREATE USER 'drupal'@'localhost' IDENTIFIED BY '$drupal_sql_pass';
GRANT ALL ON drupal.* TO 'drupal'@'localhost';
FLUSH PRIVILEGES;
EOF
}

install_drupal() {
    chown -R www-data:www-data $web_dir &&
    chown -R 755 $web_dir &&
    wget $drupal_download -O $drupal_tar &&
    tar -xf $drupal_tar &&
    mv -v $(tar -tf $drupal_tar | grep -o '^[^/]\+' | sort -u)/* $web_dir &&
    touch $web_dir/sites/default/settings.php &&
    chmod 666 $web_dir/sites/default/settings.php
    mkdir $web_dir/sites/default/files &&
    chmod 777 $web_dir/sites/default/files
}
downloadModules() {
    cd $web_dir"/modules"
    wget https://ftp.drupal.org/files/projects/restful-7.x-2.17.tar.gz
    wget https://ftp.drupal.org/files/projects/entity-7.x-1.10.tar.gz
    tar -xf restful-7.x-2.17.tar.gz
    tar -xf entity-7.x-1.10.tar.gz
}
echo "SUCCESS: RUN $date " >> $log_file

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  echo "ERROR: ADMIN PRIVILEGES" >> $log_file
  exit
fi

echo "Installing LAMP Server"
echo
echo "Installing software requirements via APT..."
install_reqs >> $log_file 2>&1
check_output $? "INSTALLING APT REQUIREMENTS"
echo
echo "Creating configuration files for Apache Webserver..."
create_configs >> $log_file
check_output $? "CREATING CONFIGURATION FILES FOR APACHE"
echo
echo "Finalizing changes to Apache Webserver..."
finalize_apache >> $log_file 2>&1
check_output $? "FINALIZING CHANGES TO APACHE"
echo
echo "Going through MySQL secure setup..."
config_mysql >> $log_file 2>&1
check_output $? "CONFIGURING SECURE MYSQL SETUP"
sudo sed -i "s/$mysql_pass/PasswordNotStoredInLogfile/g" $log_file
sudo sed -i "s/$drupal_sql_pass/PasswordNotStoredInLogfile/g" $log_file
echo
echo "Installing Drupal 7.54..."
install_drupal >> $log_file 2>&1
check_output $? "INSTALLING DRUPAL 7.54"
echo "YOUR MYSQL PASSWORD IS: $mysql_pass"
echo "YOUR DRUPAL MYSQL PASSWORD IS: $drupal_sql_pass"
