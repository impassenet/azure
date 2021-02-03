#!/bin/bash

# telechargement et installation wallix access manager
curl -k https://pocintegrarepo.blob.core.windows.net/pocintegrasource/accessmanager-2.1.6.5-linux-x64.sh >> accessmanager-2.1.6.5-linux-x64.sh && chmod +x accessmanager-2.1.6.5-linux-x64.sh && sh accessmanager-2.1.6.5-linux-x64.sh -q

# installation Mariadb et configuration de Mariadb
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash

yum install MariaDB-server expect fail2ban -y


# Activation du service mariadb
systemctl start mariadb.service
systemctl enable mariadb.service

# Definition du mot de passe root de mariadb
MYSQL_ROOT_PASSWORD='Password@123'

# Definition du mot de passe root de mariadb

SECURE_MYSQL=$(expect -c "

set timeout 10
spawn mysql_secure_installation

expect \"Enter current password for root (enter for none):\"
send \"\r\"
expect \"Switch to unix_socket authentication\"
send \"Y\r\"
expect \"Change the root password?\"
send \"Y\r\"
expect \"New password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Remove anonymous users?\(Press y\|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Disallow root login remotely?\(Press y\|Y for Yes, any other key for No) :\"
send \"n\r\"
expect \"Remove test database and access to it?\(Press y\|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Reload privilege tables now?\(Press y\|Y for Yes, any other key for No) :\"
send \"y\r\"
expect eof
")

echo $SECURE_MYSQL
