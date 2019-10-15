#!/bin/sh
##
hijau=$(tput setaf 2)
echo "${hijau}-------------------------------------------------"
sudo su -
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
wget https://raw.githubusercontent.com/Adepurnomo/Owncloud-auto-installer-docker-Centos7/master/docker-compose.yml

cat << EOF >> /opt/owncloud-docker-server/.env
OWNCLOUD_VERSION=10.0
OWNCLOUD_DOMAIN=localhost
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin
HTTP_PORT=80
EOF
chmod a+x /opt/owncloud-docker-server/.env

/bin/systemctl start docker.service > /dev/null 2>&1
/bin/systemctl enable docker.service > /dev/null 2>&1
echo "----------------------------------------------------------------------"
echo "${hijau}Downloading +compose file from source *Sabarr ya ganss ..."
echo "----------------------------------------------------------------------"
cd /opt/owncloud-docker-server/
docker-compose up -d
echo "----------------------------------------------------------------------"
echo "${hijau}Done ..."
host=$(hostname -I)
echo "and then acces http://$host"
echo "${hijau}Login information"
echo "${hijau}ADMIN_USERNAME=admin"
echo "${hijau}ADMIN_PASSWORD=admin"
service sshd restart > /dev/null 2>&1
echo "----------------------------------------------------------------------"

	  
