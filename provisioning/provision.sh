#!/usr/bin/env bash

# Define variables.
DRUPAL_FOLDER="drupal"
DRUPAL_FOLDER_PATH="/var/www/html/${DRUPAL_FOLDER}"
MYSQL_ROOT_PASSWORD="root"
MYSQL_USER_NAME="drupal"
MYSQL_USER_PASSWORD="drupal"
MYSQL_DATABASE_NAME="drupal"
VAGRANT_FOLDER="/vagrant"
VAGRANT_USER="vagrant"

# Install Apache2, enable modules, create vhost.
apt-get install -y apache2
a2enmod rewrite
VIRTUALHOST=$(cat <<EOF
<VirtualHost *:80>
  DocumentRoot ${DRUPAL_FOLDER_PATH}
  ErrorLog \${APACHE_LOG_DIR}/${DRUPAL_FOLDER}.error.log
  CustomLog \${APACHE_LOG_DIR}/${DRUPAL_FOLDER}.access.log combined
  <Directory "${DRUPAL_FOLDER_PATH}/">
    AllowOverride All
    Require all granted
  </Directory>
</VirtualHost>
EOF
)
echo "${VIRTUALHOST}" > /etc/apache2/sites-available/000-default.conf
service apache2 restart

# Install PHP 7.0 and some modules.
apt-get install -y libapache2-mod-php7.0 php7.0-curl php7.0-zip

# Install MySQL (need password), create user and database.
debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}"
apt-get install -y mysql-server php7.0-mysql
MY_CNF=$(cat <<EOF
[client]
host=localhost
user=root
password=${MYSQL_ROOT_PASSWORD}
EOF
)
echo "${MY_CNF}" > /root/.my.cnf
mysql -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE_NAME}.* TO '${MYSQL_USER_NAME}'@'localhost' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';"

# Install PhpMyAdmin (need password).
debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password ${MYSQL_ROOT_PASSWORD}"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password ${MYSQL_ROOT_PASSWORD}"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password ${MYSQL_ROOT_PASSWORD}"
debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
apt-get -y install phpmyadmin

# Install Composer.
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Install Drush 8.
sudo -iu ${VAGRANT_USER} composer global require drush/drush:~8.1.15
ln -sf /home/${VAGRANT_USER}/.config/composer/vendor/drush/drush/drush /usr/local/bin/drush

# Get Drupal 8.
if [ -z $(ls "${DRUPAL_FOLDER_PATH}") ]
then
  sudo -iu ${VAGRANT_USER} composer create-project drupal/drupal:8.x ${DRUPAL_FOLDER_PATH}
fi
