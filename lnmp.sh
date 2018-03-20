#!/bin/bash
echo --------------------LNMP Install--By OLiver----------------------------

#stop selinux
/etc/init.d/iptables stop
setenforce 0

#setting MariaDB yum
cat > /etc/yum.repos.d/mariadb.repo <<EOF
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1.10/centos6-amd64
gpgkey = https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck = 1
EOF


yum clean all
yum makecache

#install Development tools
yum -y groupinstall "Development Tools"

#install mariadb
yum -y install MariaDB*

#add mariadb's run user
groupadd -r mariadb
useradd -g mariadb -r mariadb -s /sbin/nologin

#start MariaDB
service mysql start

#set mariadb root password
mysqladmin -u root password '123456'

mkdir /usr/local/php

mkdir /usr/local/nginx
#install php devel
yum -y install  libxml2 libxml2-devel libcrul libcurl-devel gd gd-devel libpng libpng-devel wget


yum install -y apr* autoconf automake bison bzip2 bzip2* cloog-ppl compat* cpp curl curl-devel fontconfig fontconfig-devel freetype freetype* freetype-devel gcc gcc-c++ gtk+-devel gd gettext gettext-devel glibc kernel kernel-headers keyutils keyutils-libs-devel krb5-devel libcom_err-devel libpng libpng-devel libjpeg* libsepol-devel libselinux-devel libstdc++-devel libtool* libgomp libxml2 libxml2-devel libXpm* libtiff libtiff* make mpfr ncurses* ntp openssl openssl-devel patch pcre-devel perl php-common php-gd policycoreutils telnet t1lib t1lib* nasm nasm* zlib-devel gd-devel
#install libmcrypt
cd /usr/local/src
wget http://www.atomicorp.com/installers/atomic
chmod +x atomic
./atomic
yum -y install php-mcrypt libmcrypt libmcrypt-devel

#install php
cd /usr/local/src
wget http://cn2.php.net/distributions/php-5.6.2.tar.gz
tar zxvf php-5.6.2.tar.gz
cd php-5.6.2
./configure \
--prefix=/usr/local/php \
--with-config-file-path=/usr/local/php/etc \
--enable-fpm \
--with-fpm-user=php-fpm \
--with-fpm-group=php-fpm \
--with-mysql=mysqlnd \
--with-mysql-sock=/var/lib/mysql/mysql.sock \
--with-libxml-dir \
--with-gd \
--with-jpeg-dir \
--with-png-dir \
--with-freetype-dir \
--with-iconv-dir \
--with-zlib-dir \
--with-mcrypt \
--enable-soap \
--enable-gd-native-ttf \
--enable-ftp \
--enable-mbstring \
--enable-exif \
--disable-ipv6 \
--with-pear \
--with-curl \
--with-openssl

make && make install

cp /usr/local/src/php-5.6.2/php.ini-production /usr/local/php/etc/php.ini
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
/usr/local/php/sbin/php-fpm -t
cp /usr/local/src/php-5.6.2/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod 755 /etc/init.d/php-fpm

#add php run user
groupadd -r php-fpm
useradd -g php-fpm -r php-fpm -s /sbin/nologin

#start php-service
/etc/init.d/php-fpm start


#install 
yum install -y pcre pcre-devel openssl openssl-devel
cd /usr/local/src
wget http://nginx.org/download/nginx-1.6.2.tar.gz
tar zxvf nginx-1.6.2.tar.gz
cd nginx-1.6.2
./configure \
--prefix=/usr/local/nginx \
--with-http_ssl_module \
--with-http_realip_module \
--with-http_sub_module \
--with-http_gzip_static_module \
--with-http_stub_status_module \
--with-http_addition_module \
--with-http_dav_module \
--with-pcre


make && make install

cd /usr/local/src
cp nginx /etc/init.d/nginx
chmod +x /etc/init.d/nginx
/etc/init.d/nginx -t 

chkconfig --add nginx
chkconfig nginx on
chkconfig mysql on
chkconfig php-fpm on


/etc/init.d/nginx start

curl localhost

#add selinux
/etc/init.d/iptables start
iptables -A INPUT -p tcp --dport 80 -j ACCEPT 
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

/etc/init.d/iptables save
/etc/init.d/iptables restart

#show iptables
iptables -L

setenforce 1

#show ipaddr
/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"


echo mysql user:root,password:123456


