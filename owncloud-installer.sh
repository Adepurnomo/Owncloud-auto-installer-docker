#!/bin/bash
##
hijau=$(tput setaf 2)
echo "${hijau}-------------------------------------------------"
echo "${hijau}Please run this scripts on SU"
sudo su -
echo "${hijau}-------------------------------------------------"
echo "${hijau}configure...please wait.."
echo "-------------------------------------------------"
setenforce 0
cd /etc/sysconfig
sed -i "s|SELINUX=enforcing|SELINUX=disabled|" selinux
echo "-------------------------------------------------"
echo "white list port 80"
firewall-cmd --zone=public --add-port=80/tcp --permanent 
echo "-------------------------------------------------"
echo "white list port 443"
firewall-cmd --zone=public --add-port=443/tcp --permanent 
echo "-------------------------------------------------"
echo "white list port 8080"
firewall-cmd --zone=public --add-port=8080/tcp --permanent 
echo "-------------------------------------------------"
echo "white list port 19999"
firewall-cmd --zone=public --add-port=19999/tcp --permanent 
echo "-------------------------------------------------"
firewall-cmd --reload 
cd ~
yum install git -y > /dev/null 2>&1
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

mkdir -p /opt/owncloud-docker-server > /dev/null 2>&1
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
sed -i "1i version: '2.1'" /opt/owncloud-docker-server/docker-compose.yml
chmod 777 /opt/owncloud-docker-server/docker-compose.yml

cat << EOF >> /opt/owncloud-docker-server/.env
OWNCLOUD_VERSION=10.0
OWNCLOUD_DOMAIN=localhost
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin
HTTP_PORT=80
EOF
chmod 777 /opt/owncloud-docker-server/.env

mkdir -p /opt/netdata/
echo "
version: '3'
services:
  netdata:
    image: netdata/netdata
    hostname: owncloud
    ports:
      - 19999:19999
    cap_add:
      - SYS_PTRACE
    security_opt:
      - apparmor:unconfined
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro" >> /opt/netdata/docker-compose.yaml
chmod a+x /opt/netdata/docker-compose.yaml

cd ~
systemctl start docker.service && systemctl enable docker.service > /dev/null 2>&1
echo "----------------------------------------------------------------------"
echo "${hijau}Downloading images docker from source *Sabarr ya ganss ..."
echo "----------------------------------------------------------------------"
echo "
echo "${hijau}Buil and starting Only office document server, please wait..."
docker run -i -t -d -p 8080:80 --restart=always onlyoffice/documentserver > /dev/null 2>&1
echo "${hijau}Only office document server, started..."
echo "----------------------------------------------------------------------"
cd /opt/owncloud-docker-server/
echo "${hijau}Buil and starting Owncloud server, please wait ..."
docker-compose up -d > /dev/null 2>&1
echo "${hijau}Owncloud server, started..."
echo "----------------------------------------------------------------------"
echo "${hijau}Buil and starting Netdata please wait ..."
cd /opt/netdata/
docker-compose up -d > /dev/null 2>&1
echo "${hijau}Netdata, started..."
echo "----------------------------------------------------------------------"
echo "${hijau}Complete ..."
echo "${hijau}Enjoy !! ..."
host=$(hostname -I)
echo "and then acces owncloud web http://$host"
echo "${hijau}Login information"
echo "${hijau}ADMIN_USERNAME=admin"
echo "${hijau}ADMIN_PASSWORD=admin"
echo "Document web http://$host:8080"
echo "Netdata web http://$host:19999"
echo "----------------------------------------------------------------------"
service sshd restart > /dev/null 2>&1
sleep 10
echo "----------------------------------------------------------------------"
