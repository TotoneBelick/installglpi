#!/bin/sh

#===============================================================================
#
#          FILE: installglpi.sh
# 
#         USAGE: sudo ./installglpi.sh
# 
#   DESCRIPTION: Script installation GLPI avec server LAMP
# 
#       OPTIONS: ---
#  REQUIREMENTS: wget curl git openssl
#          BUGS: remonter de l'agent fusioninventory ne se fonctione pas en ssl
#         NOTES: Testé avec Debian v9.7, Apache2 v2.4, MariaDB v, PHP v7.2,
#		 Glpi v9.4.0, FusionInventory plugin GLPI v9.4.0+1.0,
#		 FusionInventory Agent v2.4.2-1
#	
#		 Pages de téléchargements
#		 	GLPI						: https://glpi-project.org/fr/telechargements/
#			FusionInventory plugin GLPI	: https://github.com/fusioninventory/fusioninventory-for-glpi/releases
#			FusionInventory Agent		: http://fusioninventory.org/documentation/agent/installation/linux/deb.html
#
#		 Pages de manuels
#			Apache2			: https://httpd.apache.org/docs/2.4/fr/
#			MariaDB			: https://mariadb.com/kb/en/library/documentation/
#			PHP				: https://secure.php.net/manual/fr/index.php
#			phpMyAdmin		: https://docs.phpmyadmin.net/fr/latest/
#			GLPI			: https://glpi-project.org/DOC/FR/
#			FusionInventory	: http://fusioninventory.org/documentation/
#
#        AUTHOR: Tony Ristic
#  ORGANIZATION: TSSR
#       CREATED: 22/02/2019 05:10
#      REVISION: 1.00
#===============================================================================

# MAJ & install paquet necessaires au script
apt update && apt upgrade -y
apt -y install curl wget openssl

### Déclarations variables ####
# Demande du nom de l'utilisateur dans $var1
read -p "Entrez votre nom d'utilisateur : " var1

# Chemin répertoire Téléchargements de l'utilisateur dans $var2 /home/<utilisateur>/Téléchargements
var2=/home/$var1/Téléchargements
# Chemin répertoire web dans $var3 /var/www/html
var3=/var/www/html

# Génération mdp utilisateur root de mariaDB dans $passrootmariadb
passrootmariadb=(openssl rand -base64 8)
# Génération mdp utilisateur user_glpi de mariaDB $passuserglpimariadb
passuserglpimariadb=(openssl rand -base64 8)

# Changement mdp root de mariaDB dans securemariadbcmd1
securemariadbcmd1="UPDATE mysql.user SET Password=PASSWORD('$passrootmariadb') WHERE User='root';"
# Desactivatiion connection anonyme au serveur mariaDB dans securemariadbcmd2
securemariadbcmd2="DELETE FROM mysql.user WHERE User='';"
# Désactivation connection root dans securemariadbcmd3
securemariadbcmd3="DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
# Suprimer base de donnée test de mariaDB dans securemariadbcmd4
securemariadbcmd4="DROP DATABASE IF EXISTS test;"
# Suprimer utilisateur test de mariaDB dans securemariadbcmd5
securemariadbcmd5="DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
# Recharger tous les privilèges de mariaDB dans securemariadbcmd6
securemariadbcmd6="FLUSH PRIVILEGES;"
# Ajout variables securemariadbcmd1 securemariadbcmd2 securemariadbcmd3 securemariadbcmd4 securemariadbcmd5 securemariadbcmd6 dans securemariadbcmds
securemariadbcmds="${securemariadbcmd1}${securemariadbcmd2}${securemariadbcmd3}${securemariadbcmd4}${securemariadbcmd5}${securemariadbcmd6}"

# mariaDB création utilisateur user-glpi dans mariadbcmd1
mariadbcmd1="CREATE USER 'user-glpi'@'%' IDENTIFIED BY '$passuserglpimariadb';"
# mariaDB création base de données glpi dans mariadbcmd2
mariadbcmd2="CREATE DATABASE glpi;"
# mariaDB définition des droits sur la base de données glpi pour l'utilisateur user_glpi dans mariadbcmd3
mariadbcmd3="GRANT ALL PRIVILEGES ON glpi.* TO 'user-glpi'@'%';"
# mariaDB Recharger tous les privilèges dans mariadbcmd4
mariadbcmd4="FLUSH PRIVILEGES;"
# mariadbcmd1 mariadbcmd2 mariadbcmd3 mariadbcmd4 dans mariadbcmds
mariadbcmds="${mariadbcmd1}${mariadbcmd2}${mariadbcmd3}${mariadbcmd4}"

# Message d'accueil
clear
echo "Bonjour $var1,\nNous allons procéder à l'installation de votre serveur LAMP, de GLPI,\ndu plugin Fusioninventory pour glpi et de l'agent fusioninventory"
sleep 3

#### Intallation paquets nécessaires ####
## Paquets nécessaires à Fusioninventory agent
apt -y install dmidecode hwdata ucf hdparm
apt -y install perl libuniversal-require-perl libwww-perl libparse-edid-perl
apt -y install libproc-daemon-perl libfile-which-perl libhttp-daemon-perl
apt -y install libxml-treepp-perl libyaml-perl libnet-cups-perl libnet-ip-perl
apt -y install libdigest-sha-perl libsocket-getaddrinfo-perl libtext-template-perl
## Paquets nécessaires à fusioninventory-agent-task-network
apt -y install libnet-snmp-perl libcrypt-des-perl libnet-nbname-perl
## fusioninventory-agent SNMPv3 support
apt -y install libdigest-hmac-perl
## Paquets nécessaires à fusioninventory-agent-task-deploy
apt -y install libfile-copy-recursive-perl libparallel-forkmanager-perl

#### Intallation serveur LAMP ####
apt -y install apache2 apache2-doc
apt -y install mariadb-server
apt -y install php php-xmlrpc php-cas php-imap php-ldap php-mcrypt php-apcu php-pear php-gd libmcrypt-dev mcrypt
apt -y install phpmyadmin

#### FusionInventory agent ###
# Téléchargement FusionInventory Agent version 2.4.2-1
cd $var2
wget http://ftp.fr.debian.org/debian/pool/main/f/fusioninventory-agent/fusioninventory-agent_2.4.2-1_all.deb
wget http://ftp.fr.debian.org/debian/pool/main/f/fusioninventory-agent/fusioninventory-agent-task-collect_2.4.2-1_all.deb
wget http://ftp.fr.debian.org/debian/pool/main/f/fusioninventory-agent/fusioninventory-agent-task-network_2.4.2-1_all.deb
wget http://ftp.fr.debian.org/debian/pool/main/f/fusioninventory-agent/fusioninventory-agent-task-deploy_2.4.2-1_all.deb
wget http://ftp.fr.debian.org/debian/pool/main/f/fusioninventory-agent/fusioninventory-agent-task-esx_2.4.2-1_all.deb
# Installation FusionInventory Agent version 2.4.0+1.0
dpkg -i fusioninventory-agent_2.4.2-1_all.deb
dpkg -i fusioninventory-agent-task-collect_2.4.2-1_all.deb
dpkg -i fusioninventory-agent-task-network_2.4.2-1_all.deb
dpkg -i fusioninventory-agent-task-deploy_2.4.2-1_all.deb
dpkg -i fusioninventory-agent-task-esx_2.4.2-1_all.deb

#### GLPI ####
# Téléchargement de glpi version 9.4.0
cd $var2
wget https://github.com/glpi-project/glpi/releases/download/9.4.0/glpi-9.4.0.tgz
# Décompression glpi-9.4.0.tgz dans /var/www/html/glpi
cp $var2/glpi-9.4.0.tgz $var3
cd $var3
tar xzvf glpi-9.4.0.tgz
rm glpi-9.4.0.tgz
# Téléchargement plugin fusioninventory pour glpi version 9.4.0+1.0
cd $var2
wget https://github.com/fusioninventory/fusioninventory-for-glpi/releases/download/glpi9.4.0%2B1.0/fusioninventory-9.4.0+1.0.tar.bz2
# Décompression fusioninventory-9.4.0+1.0.tar.bz2 dans /var/www/html/glpi/plugins
cp $var2/fusioninventory-9.4.0+1.0.tar.bz2 $var3/glpi/plugins
cd $var3/glpi/plugins
tar jxvf fusioninventory-9.4.0+1.0.tar.bz2
rm fusioninventory-9.4.0+1.0.tar.bz2
cd /home/$var1

# Securisation MariaDB 
mysql -uroot -p$passrootmariadb -e "$securemariadbcmds"

# Création base de données glpi et urilisateur user_glpi 
mysql -uroot -p$passrootmariadb -e "$mariadbcmds"

# Création fichier .htaccess pour interdire l'affichage du contenu du répertoire web dans un navigateur
touch $var3/.htaccess
echo "<IfModule mod_autoindex.c>\n		Options -Indexes\n</IfModule>" > $var3/.htaccess

# Création fichier info.php pour afficher les informations relative à php et ses modules dans un navigateur
touch $var3/info.php
echo "<?php phpinfo(); ?>" > $var3/info.php

# Réglage des droits de fichiers sur /var/wwww/html
chmod -R 770 $var3
chown -R root:'www-data' $var3

# Ajout de l'utilisateur au groupe www-data pour l'édition du contenue web
usermod $var1 -aG www-data

# Configuration additionnelles apache2
a2enmod rewrite
a2enmod ssl
a2ensite default-ssl

#  Modification site par deffaut A MODIFIER AVEC SED
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.old
rm /etc/apache2/sites-available/000-default.conf
cp $var2/000-default.conf /etc/apache2/sites-available/
rm $var2/000-default.conf
#echo "	<Directory /var/www/html>\n		Options Indexes FollowSymLinks\n		AllowOverride All\n		Require all granted\n	</Directory>" > /etc/apache2/sites-available/000-default.conf

#  Modification site ssl par deffaut A MODIFIER AVEC SED
cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.old
rm /etc/apache2/sites-available/default-ssl.conf
cp $var2/default-ssl.conf /etc/apache2/sites-available/
rm $var2/default-ssl.conf
#echo "	<Directory /var/www/html>\n		Options Indexes FollowSymLinks\n		AllowOverride All\n		Require all granted\n	</Directory>" > /etc/apache2/sites-available/default-ssl.conf

# Modification fichier /etc/fusioninventory/agent.cfg A MODIFIER AVEC SED
cp /etc/fusioninventory/agent.cfg /etc/fusioninventory/agent.cfg.old
echo "server = http://localhost/glpi/plugins/fusioninventory/" > /etc/fusioninventory/agent.cfg

# Création Tâche cron fusioninventory-agent
touch /etc/cron.d/fusioninventory-agent
echo "1 * * * * root /usr/bin/php7.0 /var/www/html/glpi/front/cron.php &>/dev/null" > /etc/cron.d/fusioninventory-agent

# sauuvegarde identifiants
touch $var2/Documents/loginMariaDB.txt
echo "Login MariaDB\nlogin : root\npass : $passrootmariadb\nuser : user_glpi\npass : $passuserglpimariadb" > $var2/Documents/loginMariaDB.txt
cat $var2/Documents/loginMariaDB.txt
sleep 10

# Redémarage Services
systemctl restart apache2
systemctl restart fusioninventory-agent

exit
