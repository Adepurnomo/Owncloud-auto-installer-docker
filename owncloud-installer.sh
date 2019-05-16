#!/bin/sh
##
hijau=$(tput setaf 2)
echo "${hijau}-------------------------------------------------"
echo "${hijau}Please run this scripts on SU"
echo "-------------------------------------------------"
cd /etc/sysconfig
sed -i "s|SELINUX=enforcing|SELINUX=disabled|" selinux
firewall-cmd --zone=public --add-port=80/http --permanent
firewall-cmd --zone=public --add-port=443/https --permanent
firewall-cmd --zone=public --add-port=8080/https --permanent
firewall-cmd --reload
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
echo "-------------------------------------------------"
echo "${hijau}Instlling curl..."
echo "-------------------------------------------------"
yum install curl -y > /dev/null 2>&1
echo "-------------------------------------------------"
echo "${hijau}download docker composer..please wait ..."
echo "-------------------------------------------------"
/bin/curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose > /dev/null 2>&1
chmod a+x /usr/local/bin/docker-compose > /dev/null 2>&1
echo "-------------------------------------------------"
echo "${hijau}Instlling docker..."
echo "-------------------------------------------------"
/bin/yum install docker -y > /dev/null 2>&1
echo "-------------------------------------------------"
echo "${hijau}Create instansi..."  
echo "-------------------------------------------------"
mkdir /opt/owncloud-docker-server > /dev/null 2>&1
chmod 777 /opt/owncloud-docker-server > /dev/null 2>&1
cd /opt/owncloud-docker-server > /dev/null 2>&1
wget https://raw.githubusercontent.com/Adepurnomo/owncloud-docker/master/docker-compose.yml
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
cd /opt/owncloud-docker-server/
docker-compose up 
echo "----------------------------------------------------------------------"
echo "${hijau}Done ..."
echo "${hijau}Login information"
echo "${hijau}ADMIN_USERNAME=admin"
echo "${hijau}ADMIN_PASSWORD=admin"
echo "----------------------------------------------------------------------"
echo "${hijau}MANUAL INSTALATION https://www.marksei.com/install-owncloud-10-server-centos/" 
	  
