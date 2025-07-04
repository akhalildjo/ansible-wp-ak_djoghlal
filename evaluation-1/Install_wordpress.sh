#!/bin/bash 
set -e  # Arrêter le script si une commande échoue 
echo " Mise à jour du conteneur..." 
apt update -y && 
 
echo " Installation des paquets nécessaires..." 
DEBIAN_FRONTEND=noninteractive apt install -y apache2 php 
libapache2-mod-php php-mysql mariadb-server wget unzip 
 
echo " Suppression de la page par défaut d'Apache..." 
rm -f /var/www/html/index.html 
 
echo " Démarrage d'Apache et MariaDB sans systemd..." 
# Apache 
service apache2 restart 
 
# MariaDB 
mysqld_safe --datadir=/var/lib/mysql & 
 
echo " Attente du démarrage de MariaDB..." 
sleep 10 
 
echo " Sécurisation de MariaDB..." 
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'examplerootPW';" 
mysql -uroot -pexamplerootPW -e "DELETE FROM mysql.user WHERE User='';" 
mysql -uroot -pexamplerootPW -e "DROP DATABASE IF EXISTS test;" 
mysql -uroot -pexamplerootPW -e "DELETE FROM mysql.db WHERE Db='test' OR 
Db='test\\_%';" 
mysql -uroot -pexamplerootPW -e "FLUSH PRIVILEGES;" 
 
echo " Création de la base de données WordPress..." 
mysql -uroot -pexamplerootPW -e "CREATE DATABASE wordpress;" 
mysql -uroot -pexamplerootPW -e "CREATE USER 'example'@'localhost' 
IDENTIFIED BY 'examplePW';" 
mysql -uroot -pexamplerootPW -e "GRANT ALL PRIVILEGES ON wordpress.* TO 
'example'@'localhost';" 
mysql -uroot -pexamplerootPW -e "FLUSH PRIVILEGES;" 
 
echo " Téléchargement de WordPress..." 
cd /tmp 
wget https://wordpress.org/latest.zip 
unzip latest.zip 
cp -r wordpress/* /var/www/html/ 
chown -R www-data:www-data /var/www/html 
chmod -R 755 /var/www/html 
 
echo " Création automatique du fichier wp-config.php..." 
 
cd /var/www/html 
 
cp wp-config-sample.php wp-config.php 
 
sed -i "s/database_name_here/wordpress/" wp-config.php 
sed -i "s/username_here/example/" wp-config.php 
sed -i "s/password_here/examplePW/" wp-config.php 
sed -i "s/localhost/localhost/" wp-config.php 
 
# Droits 
chown www-data:www-data wp-config.php 
chmod 640 wp-config.php 
 
echo " Configuration Apache pour WordPress..." 
cat > /etc/apache2/sites-available/wordpress.conf <<EOF 
<VirtualHost *:80> 
    ServerAdmin admin@localhost 
    DocumentRoot /var/www/html/wordpress 
    <Directory /var/www/html/wordpress> 
        AllowOverride All 
    </Directory> 
    ErrorLog \${APACHE_LOG_DIR}/error.log 
    CustomLog \${APACHE_LOG_DIR}/access.log combined 
</VirtualHost> 
EOF 
 
a2ensite wordpress.conf 
a2enmod rewrite 
service apache2 reload 
 
echo " WordPress installé sur http://localhost" 