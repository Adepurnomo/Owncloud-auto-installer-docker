#!/bin/bash
##
kuning=$(tput setaf 3)
hijau=$(tput setaf 2)
echo "${kuning}-------------------------------------------------"
echo "${kuning}        Please run this scripts on SU            "
sudo su -
echo "${kuning}-------------------------------------------------"
echo "${kuning}Configure firewalld..."
setenforce 0
mkdir -p /opt/temp/
cd /etc/sysconfig
#disbale selinux
sed -i "s|SELINUX=enforcing|SELINUX=disabled|" selinux
#configure firewall
echo "${kuning}-------------------------------------------------"
echo "${kuning}white list port 80"
firewall-cmd --zone=public --add-port=80/tcp --permanent 
echo "${kuning}-------------------------------------------------"
echo "${kuning}white list port 443"
firewall-cmd --zone=public --add-port=443/tcp --permanent 
echo "${kuning}-------------------------------------------------"
echo "${kuning}white list port 8080"
firewall-cmd --zone=public --add-port=8080/tcp --permanent 
echo "${kuning}-------------------------------------------------"
echo "${kuning}white list port 19999"
firewall-cmd --zone=public --add-port=19999/tcp --permanent 
echo "${kuning}-------------------------------------------------"
firewall-cmd --reload
 ########################################################
cd ~
echo "${kuning}Initializing....."
#Spinner tks for owner
curl -o /opt/temp/spinner.sh https://raw.githubusercontent.com/tlatsas/bash-spinner/master/spinner.sh >> /dev/null 2>&1
#docker engine, netdata compiler
yum install docker Judy-devel autoconf autoconf-archive autogen automake gcc libmnl-devel libuuid-devel libuv-devel lz4-devel nmap-ncat openssl-devel zlib-devel git -y >> /dev/null 2>&1
#docker composer
curl -L https://github.com/docker/compose/releases/download/1.25.0-rc2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose >> /dev/null 2>&1
cd ~
########################################################
hostnamectl set-hostname owncloud
git clone https://github.com/Adepurnomo/banner.git >> /dev/null 2>&1
\cp /root/banner/issue.net /etc
chmod a+x /etc/issue.net
cd /etc/ssh/ 	
sed -i "s|#Banner none|Banner /etc/issue.net|" sshd_config
chmod a+x /etc/ssh/sshd_config
rm -rf /root/banner
echo "${kuning}Create instance..."  
########################################################
mkdir -p /opt/owncloud-docker-server > /dev/null 2>&1
chmod 777 /opt/owncloud-docker-server > /dev/null 2>&1
cd /opt/owncloud-docker-server 
#Create docker-composer.yml owncloud
echo 'volumes:
  files:
    driver: local
  mysql:
    driver: local
  backup:
    driver: local
  redis:
    driver: local
services:
  owncloud:
    image: owncloud/server:${OWNCLOUD_VERSION}
    restart: always
    ports:
      - ${HTTP_PORT}:8080
    depends_on:
      - db
      - redis
    environment:
      - OWNCLOUD_DOMAIN=${OWNCLOUD_DOMAIN}
      - OWNCLOUD_DB_TYPE=mysql
      - OWNCLOUD_DB_NAME=owncloud
      - OWNCLOUD_DB_USERNAME=owncloud
      - OWNCLOUD_DB_PASSWORD=owncloud
      - OWNCLOUD_DB_HOST=db
      - OWNCLOUD_ADMIN_USERNAME=${ADMIN_USERNAME}
      - OWNCLOUD_ADMIN_PASSWORD=${ADMIN_PASSWORD}
      - OWNCLOUD_MYSQL_UTF8MB4=true
      - OWNCLOUD_REDIS_ENABLED=true
      - OWNCLOUD_REDIS_HOST=redis
    healthcheck:
      test: ["CMD", "/usr/bin/healthcheck"]
      interval: 30s
      timeout: 10s
      retries: 5
    volumes:
      - files:/mnt/data
  db:
    image: webhippie/mariadb:latest
    restart: always
    environment:
      - MARIADB_ROOT_PASSWORD=owncloud
      - MARIADB_USERNAME=owncloud
      - MARIADB_PASSWORD=owncloud
      - MARIADB_DATABASE=owncloud
      - MARIADB_MAX_ALLOWED_PACKET=64M
      - MARIADB_INNODB_LOG_FILE_SIZE=32M
    healthcheck:
      test: ["CMD", "/usr/bin/healthcheck"]
      interval: 30s
      timeout: 10s
      retries: 5
    volumes:
      - mysql:/var/lib/mysql
      - backup:/var/lib/backup
  redis:
    image: webhippie/redis:latest
    restart: always
    environment:
      - REDIS_DATABASES=1
    healthcheck:
      test: ["CMD", "/usr/bin/healthcheck"]
      interval: 30s
      timeout: 10s
      retries: 5
    volumes:
      - redis:/var/lib/redis' > /opt/owncloud-docker-server/docker-compose.yml 
#put tex on docker-composer.yml
sed -i "1i version: '2.1'" /opt/owncloud-docker-server/docker-compose.yml
chmod 777 /opt/owncloud-docker-server/docker-compose.yml
#create .env owncloud
########################################################
cat << EOF >> /opt/owncloud-docker-server/.env
OWNCLOUD_VERSION=10.0
OWNCLOUD_DOMAIN=localhost
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin
HTTP_PORT=80
EOF
chmod 777 /opt/owncloud-docker-server/.env
########################################################
cd ~
systemctl start docker.service >> /dev/null 2>&1
systemctl enable docker.service >> /dev/null 2>&1
echo "${kuning}----------------------------------------------------------------------"
source "/opt/temp/spinner.sh"
start_spinner 'Build and starting Only office document server, please wait (a minut.....'
sleep 1
cd ~
docker run -i -t -d -p 8080:80 --restart=always onlyoffice/documentserver > /dev/null 2>&1
cd /opt/temp/
stop_spinner $?
echo "${kuning}Only office document server..               ${hijau}[Started]"
sleep 5
########################################################
echo "${kuning}----------------------------------------------------------------------"
source "/opt/temp/spinner.sh"
start_spinner 'Build and starting Owncloud server, please wait (a minute......'
sleep 1
cd /opt/owncloud-docker-server/
docker-compose up -d > /dev/null 2>&1
stop_spinner $?
echo "${kuning}Owncloud server..                           ${hijau}[Started]"
sleep 5
echo "${kuning}----------------------------------------------------------------------"
########################################################
#Clone netdata from source
cd /opt
git clone https://github.com/netdata/netdata.git >> /dev/null 2>&1
#put 0 to 1 (skip) question for installer netdata
sed -i 's/TWAIT} -eq 0 /TWAIT} -eq 1 /g' /opt/netdata/netdata-installer.sh
chmod a+x /opt/netdata/netdata-installer.sh
source "/opt/temp/spinner.sh"
start_spinner 'Installing netdata, please wait (a minut....'
sleep 1
cd /opt/netdata/
./netdata-installer.sh > /dev/null 2>&1
cd /opt/temp/
stop_spinner $?
########################################################
cd ~
servis=$(systemctl status netdata | grep Active)
echo "${kuning}Netdata status..       ${hijau}$servis"
sleep 10
rm -rf /opt/temp
########################################################
echo "${hijau}Complete ..."
echo "${hijau}Enjoy !! ..."
host=$(hostname -I)
echo "${kuning}----------------------------------------------------------------------"
echo "for owncloud acces http://$host"
echo "${hijau}Login information"
echo "${hijau}ADMIN_USERNAME=admin"
echo "${hijau}ADMIN_PASSWORD=admin"
echo "${kuning}----------------------------------------------------------------------"
echo "for Document server acces http://$host:8080"
echo "${kuning}----------------------------------------------------------------------"
echo "for Netdata acces http://$host:19999"
echo "${kuning}----------------------------------------------------------------------"
service sshd restart > /dev/null 2>&1
