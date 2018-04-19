#!/bin/bash
#

#Yum依赖包
yum install -y bash glibc gcc gcc-c++ openssl-devel zlib-devel pcre-devel libtool perl-devel automake gd gd-devel libjpeg* libpng* php-common php-gd ncurses* libtool* libxml2 libxml2-devel

#编译Nginx
tar zxf nginx-1.7.10.tar.gz 
cd nginx-1.7.10
./configure --prefix=/usr/local/nginx --user=nginx --group=nginx --with-http_ssl_module --with-http_gzip_static_module \
--with-http_stub_status_module --http-fastcgi-temp-path=/usr/local/nginx/fcgi
make && make install

#添加账号
useradd -m -s /bin/bash nagios
useradd nginx -d /dev/null -s /sbin/nologin
groupadd nagcmd
usermod -a -G nagcmd nagios
usermod -a -G nagcmd nginx

#编译Nagios
#wget http://sourceforge.net/projects/nagios-cn/files/sourcecode/zh_CN%203.2.3/nagios-cn-3.2.3.tar.bz2
cd ..
tar xf nagios-cn-3.2.3.tar.bz2
cd nagios-cn-3.2.3
./configure --prefix=/usr/local/nagios --with-command-group=nagcmd
make all
make install
make install-init
make install-config
make install-commandmode
chmod o+rwx /usr/local/nagios/var/rw 

#编译Nagios-plugins
#wget http://nagios-plugins.org/download/nagios-plugins-2.0.3.tar.gz
cd ..
tar zxvf nagios-plugins-2.0.3.tar.gz
cd  nagios-plugins-2.0.3
./configure --prefix=/usr/local/nagios --with-nagios-user=nagios --with-nagios-gourp=nagios 
make
make install

#编译Nrpe
#wget http://iweb.dl.sourceforge.net/project/nagios/nrpe-2.x/nrpe-2.13/nrpe-2.13.tar.gz
cd ..
tar zxf nrpe-2.13.tar.gz 
cd nrpe-2.13
./configure
make all
make install-plugin
make install-daemon
make install-daemon-config

#启动Nrpe
/usr/local/nagios/bin/nrpe -c /usr/local/nagios/etc/nrpe.cfg -d
lsof -i:5666
/usr/local/nagios/libexec/check_nrpe -H localhost -c check_users

#加载Nagios服务
chkconfig --add nagios
chkconfig nagios on
chown nagios.nagcmd /usr/local/nagios/var/rw

vim ~/.bashrc
alias check='/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg'
source ~/.bashrc

# 取消用户认证(方便调试)
# htpasswd -C /usr/local/nagios/etc/htpasswd.users nagiosadmin
sed -i 's#use_authentication=1#use_authentication=0#' /usr/local/nagios/etc/cgi.cfg

#编译Fastcgi perl
wget http://search.cpan.org/CPAN/authors/id/B/BO/BOBTFISH/FCGI-0.70.tar.gz
wget http://search.cpan.org/CPAN/authors/id/G/GB/GBARR/IO-1.25.tar.gz
wget http://search.cpan.org/CPAN/authors/id/I/IN/INGY/IO-All-0.41.tar.gz
wget http://www.mike.org.cn/wp-content/uploads/2011/07/perl-fcgi.zip

cd ..
tar zxvf FCGI-0.70.tar.gz
cd FCGI-0.70
perl Makefile.PL
make 
make install

cd ..
tar zxf IO-1.25.tar.gz 
cd IO-1.25
perl Makefile.PL 
make 
make install

cd ..
tar zxf IO-All-0.41.tar.gz 
cd IO-All-0.41
perl Makefile.PL 
make 
make install

cd ..
unzip perl-fcgi.zip 
cp perl-fcgi.pl /usr/local/nginx/
chmod 755 /usr/local/nginx/perl-fcgi.pl

#Perl脚本
cat >> /usr/local/nginx/start_perl_cgi << EOF
#!/bin/bash
#set -x
dir=/usr/local/nginx

stop ()
{
#pkill  -f  $dir/perl-fcgi.pl
kill $(cat $dir/logs/perl-fcgi.pid)
rm $dir/logs/perl-fcgi.pid 2>/dev/null
rm $dir/logs/perl-fcgi.sock 2>/dev/null
echo "stop perl-fcgi done"
}

start ()
{
rm $dir/now_start_perl_fcgi.sh 2>/dev/null

chown nginx.root $dir/logs
echo "$dir/perl-fcgi.pl -l $dir/logs/perl-fcgi.log -pid $dir/logs/perl-fcgi.pid -S $dir/logs/perl-fcgi.sock" >>$dir/now_start_perl_fcgi.sh

chown nginx.nginx $dir/now_start_perl_fcgi.sh
chmod u+x $dir/now_start_perl_fcgi.sh

sudo -u nginx $dir/now_start_perl_fcgi.sh
echo "start perl-fcgi done"
}

case $1 in
stop)
stop
;;
start)
start
;;
restart)
stop
sleep 2
start
;;
esac

EOF

#权限及启动
chmod 755 /usr/local/nginx/start_perl_cgi

/usr/local/nginx/start_perl_cgi start


#配置nginx-server
sed -i '/# HTTPS server/i include /usr/local/nginx/conf.d/*.conf;' /usr/local/nginx/conf/nginx.conf

mkdir /usr/local/nginx/conf.d/

cat >> /usr/local/nginx/conf.d/default.conf << EOF
server {
    listen       80;
    server_name  nagios.a.com;

    charset utf-8;

#    auth_basic "Nagios Access";
#   auth_basic_user_file /usr/local/nagios/etc/htpasswd.users;	
	
    location / {
        root   /usr/local/nagios/share;
        index  index.html index.htm index.php;
    }

    location ~ .*\.(php|php5)?$
    {
      root /usr/local/nagios/share;
      fastcgi_pass  unix:/tmp/php-cgi.sock;
      fastcgi_index index.php;
      include fastcgi.conf;
    }

    location /nagios {
        alias /usr/local/nagios/share;
#        auth_basic "Nagios Access";
#       auth_basic_user_file /usr/local/nagios/etc/htpasswd.users;
    }

    location /cgi-bin/images {
        alias /usr/local/nagios/share/images;
    }

    location /cgi-bin/stylesheets {
        alias /usr/local/nagios/share/stylesheets;
    }

    location /cgi-bin {
        alias /usr/local/nagios/sbin;
    }

    location ~ .*\.(cgi|pl)?$
    {
      gzip off;
      root   /usr/local/nagios/sbin;
      rewrite ^/nagios/cgi-bin/(.*)\.cgi /$1.cgi break;
      fastcgi_pass  unix:/usr/local/nginx/logs/perl-fcgi.sock;
      fastcgi_index index.cgi;
	  fastcgi_param SCRIPT_FILENAME  /usr/local/nagios/sbin$fastcgi_script_name;
      fastcgi_param HTTP_ACCEPT_LANGUAGE zh-cn;
	  fastcgi_param  REMOTE_USER        $remote_user;
      include fastcgi.conf;
      fastcgi_read_timeout   60;
	  
#      auth_basic "Nagios Access";
#      auth_basic_user_file /usr/local/nagios/etc/htpasswd.users;
    }
}
EOF

echo "Nagios_cn Install is ok!!!"








