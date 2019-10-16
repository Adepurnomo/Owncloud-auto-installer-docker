#!/bin/bash
##
hijau=$(tput setaf 2)
echo "${hijau}-------------------------------------------------"
#sudo su -
echo "${hijau}Please run this scripts on SU"
echo "-------------------------------------------------"
echo "${hijau}-------------------------------------------------"
echo "${hijau}configure....."
echo "-------------------------------------------------"
setenforce 0
cd /etc/sysconfig
sed -i "s|SELINUX=enforcing|SELINUX=disabled|" selinux
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --reload
hostnamectl set-hostname owcloud
/bin/yum install git -y > /dev/null 2>&1

yum install Judy-devel autoconf autoconf-archive autogen automake gcc libmnl-devel libuuid-devel libuv-devel lz4-devel nmap-ncat openssl-devel zlib-devel -y > /dev/null 2>&1
cd /root/
/bin/git clone https://github.com/Adepurnomo/banner.git
\cp /root/banner/issue.net /etc
/bin/chmod a+x /etc/issue.net
cd /etc/ssh/ 	
/bin/sed -i "s|#Banner none|Banner /etc/issue.net|" sshd_config
/bin/chmod a+x /etc/ssh/sshd_config
/bin/rm -rf /root/banner

sleep 10
echo "-------------------------------------------------"
echo "${hijau}Working....."
echo "-------------------------------------------------"
yum install wget -y > /dev/null 2>&1
echo "-------------------------------------------------"
echo "${hijau}get docker composer..please wait ..."
echo "-------------------------------------------------"
/bin/curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose > /dev/null 2>&1
chmod a+x /usr/local/bin/docker-compose > /dev/null 2>&1
echo "-------------------------------------------------"
echo "${hijau}Installing docker..."
echo "-------------------------------------------------"
/bin/yum install docker -y > /dev/null 2>&1
echo "-------------------------------------------------"
echo "${hijau}Create instance..."  
echo "-------------------------------------------------"
mkdir /opt/owncloud-docker-server > /dev/null 2>&1
chmod 777 /opt/owncloud-docker-server > /dev/null 2>&1
cd /opt/owncloud-docker-server > /dev/null 2>&1
#wget https://raw.githubusercontent.com/Adepurnomo/Owncloud-auto-installer-docker-Centos7/master/docker-compose.yml

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

/bin/systemctl start docker.service > /dev/null 2>&1
/bin/systemctl enable docker.service > /dev/null 2>&1
echo "----------------------------------------------------------------------"
echo "${hijau}Downloading +compose file from source *Sabarr ya ganss ..."
echo "----------------------------------------------------------------------"
cd /opt/owncloud-docker-server/
docker-compose up -d

mkdir /opt/netdata/
chmod 777 /opt/netdata/
cat << EOF >> /opt/netdata/docker-compose.yml
version: '3'
services:
  netdata:
    image: netdata/netdata
    hostname: example.com # set to fqdn of host
    ports:
      - 19999:19999
    cap_add:
      - SYS_PTRACE
    security_opt:
      - apparmor:unconfined
    volumes:
      - /etc/passwd:/host/etc/passwd:ro
      - /etc/group:/host/etc/group:ro
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
EOF

chmod 777 /opt/netdata/docker-compose.yml
cd /opt/netdata/
docker-compose up -d
cd ~


echo "----------------------------------------------------------------------"
echo "${hijau}Done ..."
host=$(hostname -I)
echo "and then acces owncloud http://$host"
echo "${hijau}Login information"
echo "${hijau}ADMIN_USERNAME=admin"
echo "${hijau}ADMIN_PASSWORD=admin"
echo "----------------------------------------------------------------------"
echo "and then acces netdata http://$host:19999"
service sshd restart > /dev/null 2>&1
echo "----------------------------------------------------------------------"
sleep 10
