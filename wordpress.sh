#!/bin/bash

#DECLARACIÓN DE LAS VARIABLES
HTTPASSWD_DIR=/home/ubuntu
DB_ROOT_PASSWD=root
DB_NAME=wordpress_db
DB_USER=wordpress_user
DB_PASSWORD=wordpress_password
PHPMYADMIN_PASSWD=`tr -dc A-Za-z0-9 < /dev/urandom | head -c 64`


# ---------------------------
# INSTALACIÓN DE LA PILA LAMP|
# ---------------------------
#Activamos la depuración del script
set -x

#Actualizamos la lista de paquetes y los actualizamos
apt update -y
apt upgrade -y

#INSTALACIÓN APACHE 
apt install apache2 -y


#INSTALACIÓN MYSQL 
apt install mysql-server -y


#INSTALACIÓN PHP
#Instalamos módulos PHP 
apt install php libapache2-mod-php php-mysql -y

#Reiniciamos el servicio Apache2
systemctl restart apache2

#Copiamos el archivo info.php a la carpeta html
cp $HTTPASSWD_DIR/info.php /var/www/html


#INSTALACIÓN PHPMYADMIN
#Configuramos las opciones de instalación de phpMyAdmin
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_PASSWD" |debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_PASSWD" | debconf-set-selections

#Instalamos phpMyAdmin 
apt install phpmyadmin php-mbstring php-zip php-gd php-json php-curl -y



#---------------------
#INSTALACIÓN WORDPRESS|
#---------------------
#Vamos al directorio al que se instalará
cd /var/www/html

#Descargamos la última versión de Wordpress que hay disponible
wget http://wordpress.org/latest.tar.gz

#Eliminamos instalaciones anteriores para que no nos den problemas en una posible reinstalación
rm -rf /var/www/html/wordpress

#Descomprimimos el archivo de Wordpress 
tar -xzvf latest.tar.gz

#Eliminamos lo que ya no necesitamos 
rm -rf latest.tar.gz


#CREACIÓN DE LA BASE DE DATOS DE WORDPRESS
#Aquí vamos a introducir gran parte de las variables que creamos anteriormente al principio del script

#Nos aseguramos de que la base de datos que vamos a crear no existe, y si existe, la borramos
mysql -u root <<< "DROP DATABASE IF EXISTS $DB_NAME;"

#Creamos la base de datos
mysql -u root <<< "CREATE DATABASE $DB_NAME;"

#Nos aseguramos de que no existe el usuario que vamos a crear, y si existe, lo borramos
mysql -u root <<< "DROP USER IF EXISTS $DB_USER@localhost;"

#Creamos el usuario para Wordpress
mysql -u root <<< "CREATE USER $DB_USER@localhost IDENTIFIED BY '$DB_PASSWORD';"

#Concedemos privilegios a nuestro usuario
mysql -u root <<< "GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER@localhost;"

#Aplicamos cambios con un FLUSH
mysql -u root <<< "FLUSH PRIVILEGES;"



#CONFIGURAIÓN DEL ARCHIVO WP-CONFIG
#Renombramos el archivo de configuración
mv /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php

#Definimos nuestras variables dentro del archivo wp-config.php
sed -i "s/database_name_here/$DB_NAME/" /var/www/html/wordpress/wp-config.php
sed -i "s/username_here/$DB_USER/" /var/www/html/wordpress/wp-config.php
sed -i "s/password_here/$DB_PASSWORD/" /var/www/html/wordpress/wp-config.php

#Para que al iniciar el sitio nos aparezca Wordpress, borramos el index.html de Apache2
rm -rf /var/www/html/index.html

#Copiamos el archivo index.php al directorio html
cp /var/www/html/wordpress/index.php  /var/www/html/index.php

#Editamos el archivo index.php 
sed -i "s#/wp-blog-header.php#/wordpress/wp-blog-header.php#" /var/www/html/index.php

#Copiamos el archivo htaccess y le ponemos el punto delante para que sea oculto y tenga efecto
cp $HTTPASSWD_DIR/htaccess /var/www/html/.htaccess


#CONFIGURACIÓN DE LAS SECURITY KEYS
#Borramos el bloque que nos viene por defecto en el archivo de configuración, ya que es muy inseguro
sed -i "/AUTH_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/SECURE_AUTH_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/LOGGED_IN_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/NONCE_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/AUTH_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/SECURE_AUTH_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/LOGGED_IN_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/NONCE_SALT/d" /var/www/html/wordpress/wp-config.php

#Creamos la variable SECURITY_KEYS guardando dentro de ella todas las claves
SECURITY_KEYS=$(curl https://api.wordpress.org/secret-key/1.1/salt/)

#Para que no nos falle el sed sustituimos dentro del contenido de SECURITY KEYS todas las "/" por "_"
SECURITY_KEYS=$(echo $SECURITY_KEYS | tr / _)

#Creamos un nuevo bloque de SECURITY KEYS en el que se introducirá la variable que hemos creado antes debajo del @-
sed -i "/@-/a $SECURITY_KEYS" /var/www/html/wordpress/wp-config.php

#Habilitamos el módulo rewrite (reescritura de las url)
a2enmod rewrite

#Le damos permiso a la carpeta de wordpress
chown -R www-data:www-data /var/www/html

#Reiniciamos el sercicio de Apache2
systemctl restart apache2
