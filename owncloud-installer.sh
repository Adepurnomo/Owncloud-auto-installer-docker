#!/bin/bash
##
hijau=$(tput setaf 2)
echo "${hijau}-------------------------------------------------"
#sudo su -
cd ~
chmod 777 owncloud-installer.sh
echo "${hijau}Please run this scripts on SU"
echo "-------------------------------------------------"
echo "${hijau}configure...please wait.."
echo "-------------------------------------------------"
cd /etc/sysconfig
setenforce 0
sed -i "s|SELINUX=enforcing|SELINUX=disabled|" selinux
firewall-cmd --zone=public --add-port=80/tcp --permanent 
firewall-cmd --zone=public --add-port=443/tcp --permanent 
firewall-cmd --reload 
cd ~
yum install git curl install Judy-devel autoconf autoconf-archive autogen automake gcc libmnl-devel libuuid-devel libuv-devel lz4-devel nmap-ncat openssl-devel zlib-devel -y > /dev/null 2>&1
hostnamectl set-hostname owncloud
cd ~
git clone https://github.com/Adepurnomo/banner.git 
\cp /root/banner/issue.net /etc
chmod a+x /etc/issue.net
cd /etc/ssh/ 	
sed -i "s|#Banner none|Banner /etc/issue.net|" sshd_config
chmod a+x /etc/ssh/sshd_config
rm -rf /root/banner

echo "-------------------------------------------------"
echo "${hijau}Working....."
echo "-------------------------------------------------"
echo "${hijau}get docker composer..please wait ..."
echo "-------------------------------------------------"
curl -L https://github.com/docker/compose/releases/download/1.25.0-rc2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose > /dev/null 2>&1
chmod +x /usr/local/bin/docker-compose
echo "${hijau}Installing docker..."
echo "-------------------------------------------------"
yum install docker -y > /dev/null 2>&1
echo "${hijau}Create instance..."  
echo "-------------------------------------------------"

mkdir /opt/owncloud-docker-server > /dev/null 2>&1
chmod 777 /opt/owncloud-docker-server > /dev/null 2>&1
cd /opt/owncloud-docker-server > /dev/null 2>&1
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
      - MARIADB_MAX_ALLOWED_PACKET=128M
      - MARIADB_INNODB_LOG_FILE_SIZE=64M
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
sed  -i "1i version: '2.1'" /opt/owncloud-docker-server/docker-compose.yml
chmod 777 /opt/owncloud-docker-server/docker-compose.yml

cat << EOF >> /opt/owncloud-docker-server/.env
OWNCLOUD_VERSION=10.0
OWNCLOUD_DOMAIN=localhost
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin
HTTP_PORT=80
EOF
chmod 777 /opt/owncloud-docker-server/.env

cd /opt
git clone https://github.com/netdata/netdata.git
sed -i 's/WAIT} -eq 0/WAIT} -eq 1/g' /opt/netdata/netdata-installer.sh
chmod 7777 /opt/netdata/netdata-installer.sh
cd /opt/netdata
sh netdata-installer.sh

echo "----------------------------------------------------------------------"
echo "${hijau}Downloading +compose file from source *Sabarr ya ganss ..."
echo "----------------------------------------------------------------------"

systemctl start docker.service > /dev/null 2>&1
systemctl enable docker.service > /dev/null 2>&1
cd /opt/owncloud-docker-server/
docker-compose up -d

echo "----------------------------------------------------------------------"
echo "${hijau}Done ..."
host=$(hostname -I)
echo "and then acces owncloud http://$host"
echo "${hijau}Login information"
echo "${hijau}ADMIN_USERNAME=admin"
echo "${hijau}ADMIN_PASSWORD=admin"
echo "and then acces netdata http://$host:19999"
echo "----------------------------------------------------------------------"
service sshd restart > /dev/null 2>&1
sleep 10
echo "----------------------------------------------------------------------"

