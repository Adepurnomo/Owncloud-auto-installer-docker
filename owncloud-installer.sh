#!/bin/sh
##
hijau=$(tput setaf 2)
echo "${hijau}######################################"
echo "${hijau}Please run this scripts on SU"
echo "######################################"
/bin/yum install git -y > /dev/null 2>&1
cd /root/
/bin/git clone https://github.com/Adepurnomo/test.git
\cp /root/test/issue.net /etc
chmod a+x /etc/issue.net
cd /etc/ssh/ 	
sed -i "s|#Banner none|Banner /etc/issue.net|" sshd_config
chmod a+x /etc/ssh/sshd_config
#service sshd restart
rm -rf /root/test
sleep 10
echo "######################################"
echo "${hijau}Instlling curl..."
echo "######################################"
yum install curl -y > /dev/null 2>&1
echo "-------------------------------------------------"
echo "${hijau}download docker composer..please wait ..."
echo "-------------------------------------------------"
/bin/curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose > /dev/null 2>&1
chmod a+x /usr/local/bin/docker-compose > /dev/null 2>&1
echo "######################################"
echo "${hijau}Instlling docker..."
echo "######################################"
/bin/yum install docker -y > /dev/null 2>&1
echo "######################################"
echo "${hijau}Create instansi..."  
echo "######################################"
mkdir /opt/owncloud-docker-server > /dev/null 2>&1
chmod 777 /opt/owncloud-docker-server > /dev/null 2>&1
##########################################################################
cat << EOF >> /opt/owncloud-docker-server/docker-compose.yml
version: '2.1'

volumes:
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
      - redis:/var/lib/redis
EOF
chmod a+x /opt/owncloud-docker-server/docker-compose.yml
sleep 5
##########################################################################
cat << EOF >> /opt/owncloud-docker-server/.env
OWNCLOUD_VERSION=10.0
OWNCLOUD_DOMAIN=localhost
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin
HTTP_PORT=80
EOF
chmod a+x /opt/owncloud-docker-server/.env
##########################################################################
/bin/systemctl start docker.service > /dev/null 2>&1
/bin/systemctl enable docker.service > /dev/null 2>&1
echo "----------------------------------------------------------------------"
echo "${hijau}Downloading +compose file from source *Sabarr ya ganss ..."
echo "----------------------------------------------------------------------"
docker-compose up 
echo "######################################"
echo "${hijau}Done ..."
echo "${hijau}Login information"
echo "${hijau}ADMIN_USERNAME=admin"
echo "${hijau}ADMIN_PASSWORD=admin"
echo "######################################"
echo "${hijau}MANUAL INSTALATION https://www.marksei.com/install-owncloud-10-server-centos/" 
	  
