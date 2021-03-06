#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp"
    exit 1
fi

clear
echo "========================================================================="
echo "Install LNMP v1.0 for CentOS"
echo "A tool to auto-compile & install Nginx+MySQL+PHP on Linux For more information please visit http://www.boxcore.org/"
echo "========================================================================="
# close var cur_dir now
cur_dir=$(pwd)

#set mysql root password
	echo "==========================="
	# close var mysqlrootpwd
	mysqlrootpwd="root"
	echo "Please input the root password of mysql:"
	read -p "(Default password: root):" mysqlrootpwd
	if [ "$mysqlrootpwd" = "" ]; then
		mysqlrootpwd="root"
	fi
	echo "==========================="
	echo "MySQL root password:$mysqlrootpwd"
	echo "==========================="


function InitInstall()
{
	echo "================================================================="
	echo " Remove Basic LNMP and donwload install basic lib "
	echo "================================================================="
	cd $cur_dir
	cat /etc/issue
	uname -a
	MemTotal=`free -m | grep Mem | awk '{print  $2}'`  
	echo -e "\n Memory is: ${MemTotal} MB "
	#Set timezone
	rm -rf /etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

	yum install -y ntp
	ntpdate -u pool.ntp.org
	date

	rpm -qa|grep httpd
	rpm -e httpd
	rpm -qa|grep mysql
	rpm -e mysql
	rpm -qa|grep php
	rpm -e php

	yum -y remove httpd*
	yum -y remove php*
	yum -y remove mysql-server mysql
	yum -y remove php-mysql

	yum -y install yum-fastestmirror
	yum -y remove httpd
	#yum -y update

	#Disable SeLinux
	if [ -s /etc/selinux/config ]; then
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	fi

	cp /etc/yum.conf /etc/yum.conf.lnmp
	sed -i 's:exclude=.*:exclude=:g' /etc/yum.conf

	for packages in wget make patch cmake gcc gcc-c++ gcc-g77 flex bison file libtool libtool-libs autoconf kernel kernel-devel kernel-headers libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glib2 glib2-devel bzip2 bzip2-devel libevent libevent-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel vim-minimal nano fonts-chinese gettext gettext-devel gmp-devel pspell-devel unzip libcap;
	do yum -y install $packages; done
	
	for packages in automake compat* cpp cloog-ppl ppl glibc jpegsrc keyutils keyutils-libs-devel libcom_err-devel libgomp libiconv libjpeg* libmcrypt libmcrypt-devel libsepol-devel libselinux-devel libXpm* libstdc++-devel mhash mpfr pcre-devel  perl php-gd php-common python-devel fontconfig cmake apr* ncurses ncurses-devel;
	do yum -y install $packages; done

	mv -f /etc/yum.conf.lnmp /etc/yum.conf
	yum clean all
	
	echo "================================================================="
	echo " Install axel-1.0b "
	echo "================================================================="
	if [ -s axel-1.0b.tar.gz ]; then
	  echo "axel-1.0b.tar.gz [found]"
	else
	  echo "Error: axel-1.0b.tar.gz not found!!!download now......"
	  wget http://mirrors.boxcore.org/lnmp/axel-1.0b.tar.gz
	fi
	tar zxvf axel-1.0b.tar.gz
	cd axel-1.0b
	./configure
	make && make install
	cd ../
	
	
}


function CheckAndDownloadLibFiles()
{
echo "============================check files=================================="
cd $cur_dir

if [ -s php-5.3.28.tar.gz ]; then
  echo "php-5.3.28.tar.gz [found]"
else
  echo "Error: php-5.3.28.tar.gz not found!!!download now......"
  axel -n 10 http://mirrors.sohu.com/php/php-5.3.28.tar.gz
fi

if [ -s mysql-5.5.35.tar.gz ]; then
  echo "mysql-5.5.35.tar.gz [found]"
else
  echo "Error: mysql-5.5.35.tar.gz not found!!!download now......"
  axel -n 10 http://mirrors.boxcore.org/lnmp/mysql-5.5.35.tar.gz
fi

if [ -s nginx-1.4.4.tar.gz ]; then
  echo "nginx-1.4.4.tar.gz [found]"
  else
  echo "Error: nginx-1.4.4.tar.gz not found!!!download now......"
  axel -n 10 http://mirrors.boxcore.org/lnmp/nginx-1.4.4.tar.gz
fi

if [ -s conf.tar.gz ]; then
  echo "conf.tar.gz [found]"
  else
  echo "Error: conf.tar.gz not found!!!download now......"
  axel -n 10 http://mirrors.boxcore.org/lnmp/conf.tar.gz
fi

echo "============================check files=================================="
}

# install MYSQL
function InstallMYSQL()
{
echo "============================Install MySQL================================="
cd $cur_dir
mkdir -pv /var/mysql/data
groupadd -r mysql
useradd -g mysql -r -s /bin/false -M -d /var/mysql/data mysql
chown mysql:mysql /var/mysql/data
tar -zxf /root/lnmp/mysql-5.5.35.tar.gz
cd /root/lnmp/mysql-5.5.35
cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/var/mysql/data -DSYSCONFDIR=/etc -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DENABLED_LOCAL_INFILE=1 -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DEXTRA_CHARSETS=utf8 -DMYSQL_TCP_PORT=3306 -DMYSQL_USER=mysql -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DWITH_SSL=yes -DWITH_PARTITION_STORAGE_ENGINE=1 -DINSTALL_PLUGINDIR=/usr/local/mysql/plugin -DWITH_DEBUG=0
make && make install

cp -rf /usr/local/mysql/support-files/my-medium.cnf /etc/my.cnf
sed '/skip-external-locking/i\datadir = /var/mysql/data' -i /etc/my.cnf
sed -i 's:#innodb:innodb:g' /etc/my.cnf
sed -i 's:/usr/local/mysql/data:/var/mysql/data:g' /etc/my.cnf

chmod 755 /usr/local/mysql/scripts/mysql_install_db
/usr/local/mysql/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=/var/mysql/data --user=mysql
chown -R mysql /usr/local/mysql/var
chgrp -R mysql /usr/local/mysql/.

cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
chmod 755 /etc/init.d/mysql
chkconfig mysqld on
echo 'export PATH=/usr/local/mysql/bin:$PATH' >> /etc/profile

cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib
/usr/local/lib
EOF
ldconfig

ln -s /usr/local/mysql/lib/mysql /usr/lib/mysql
ln -s /usr/local/mysql/include/mysql /usr/include/mysql
if [ -d "/proc/vz" ];then
ulimit -s unlimited
fi
/etc/init.d/mysql start

ln -s /usr/local/mysql/bin/mysql /usr/bin/mysql
ln -s /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump
ln -s /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk
ln -s /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe

/usr/local/mysql/bin/mysqladmin -u root password $mysqlrootpwd

cat > /tmp/mysql_sec_script<<EOF
use mysql;
update user set password=password('$mysqlrootpwd') where user='root';
delete from user where not (user='root') ;
delete from user where user='root' and password=''; 
drop database test;
DROP USER ''@'%';
flush privileges;
EOF

/usr/local/mysql/bin/mysql -u root -p$mysqlrootpwd -h localhost < /tmp/mysql_sec_script

rm -f /tmp/mysql_sec_script

/etc/init.d/mysql restart
/etc/init.d/mysql stop
echo "============================MySQL 5.5.35 install completed========================="

}


# install Nginx
function InstallNginx()
{
echo "============================Install Nginx================================="
cd $cur_dir
groupadd www
useradd -s /sbin/nologin -g www www

#tar zxvf pcre-8.34.tar.gz
#cd pcre-8.34/
#./configure
#make && make install
#cd ../

ldconfig

tar zxvf nginx-1.4.4.tar.gz
cd nginx-1.4.4/
./configure --user=www --group=www --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_gzip_static_module --with-ipv6 --with-openssl=/usr/include/openssl --with-pcre
make && make install
cd ../

tar zxvf conf.tar.gz
rm -rf /etc/rc.d/init.d/nginx
cp conf/nginx /etc/rc.d/init.d/nginx
chmod 775 /etc/rc.d/init.d/nginx
chkconfig nginx on
/etc/rc.d/init.d/nginx restart
service nginx restart

ln -s /usr/local/nginx/sbin/nginx /usr/bin/nginx

#rm -f /usr/local/nginx/conf/nginx.conf
#cd /root/lnmp
#cp conf/nginx.conf /usr/local/nginx/conf/nginx.conf
#cp conf/www-conf /home/www/conf

cd $cur_dir

mkdir -p /home/www/{default,logs}
chmod +w /home/www/default
chmod 777 /home/www/logs

chown -R www:www /home/www
}

# install apache depand
function InstallLib()
{
cd /root/lnmp

yum -y install python-devel

# install zlib
echo "#============================================================================#"
echo "Install zlib"
echo "#============================================================================#"
	tar zxvf zlib-1.2.5.tar.gz
	cd zlib-1.2.5
	./configure --prefix=/usr/local/zlib
	make && make install
	cd ../

# install libpng
echo "#============================================================================#"
echo "Install libpng"
echo "#============================================================================#"
	tar zxvf libpng-1.6.2.tar.gz
	cd libpng-1.6.2
	cp scripts/makefile.linux ./makefile
	sed -i 's:ZLIBLIB=../zlib:ZLIBLIB=/usr/local/zlib/lib:g' makefile
	sed -i 's:ZLIBINC=../zlib:ZLIBINC=/usr/local/zlib/include:g' makefile
	./configure --prefix=/usr/local/libpng
	make && make install
	cd ../

# install freetype(ttf)
echo "#============================================================================#"
echo "Install freetype"
echo "#============================================================================#"
	tar zxvf freetype-2.5.3.tar.gz
	#  install freetype depand bzip2 harfbuzz
	yum install -y bzip2-devel
	cd freetype-2.5.3
	./configure --prefix=/usr/local/freetype
	make && make install
	cd ../

# install jpegsrc
echo "#============================================================================#"
echo "Install jpegsrc"
echo "#============================================================================#"
	tar zxvf jpegsrc.v9a.tar.gz
	cd jpeg-9a
	mkdir -pv /usr/local/libjpeg/{,bin,lib,include,man/man1,man1}
	./configure --prefix=/usr/local/libjpeg --enable-shared --enable-static
	make && make install
	cd ../

# install libxml2
echo "#============================================================================#"
echo "Install libxml2"
echo "#============================================================================#"
	tar zxvf libxml2-2.9.1.tar.gz
	cd libxml2-2.9.1
	./configure --prefix=/usr/local/libxml2
	make && make install
	cp xml2-config /usr/bin/
	cd ../

# install libmcrypt
echo "#============================================================================#"
echo "Install libmcrypt"
echo "#============================================================================#"
	tar zxvf libmcrypt-2.5.8.tar.gz
	cd libmcrypt-2.5.8
	./configure
	make && make install
	cd ../

# install gd
echo "#============================================================================#"
echo "Install gd2"
echo "#============================================================================#"
	tar zxvf gd-2.0.35.tar.gz
	cd gd-2.0.35
	./configure --prefix=/usr/local/libgd --with-png=/usr/local/libpng --with-freetype=/usr/local/freetype --with-jpeg=/usr/local/libjpeg --with-fontconfig=/usr/local/fontconfig --enable-libxml2
	make && make install
	cd ../

# conf lib
echo "#============================================================================#"
echo "conf lib for ldconfig"
echo "#============================================================================#"
	cat >>/etc/ld.so.conf<<eof
	/usr/local/zlib/lib
	/usr/local/freetype/lib
	/usr/local/libjpeg/lib
	/usr/local/libgd/lib
	eof
	ldconfig
}

mkdir -pv logs
InitInstall 2>&1 | tee -a logs/InitInstall-`date +%Y%m%d`.log
CheckAndDownloadLibFiles 2>&1 | tee -a logs/CheckAndDownloadLibFiles-`date +%Y%m%d`.log
InstallMYSQL 2>&1 | tee -a logs/InstallMYSQL-`data +%Y%m%d`.log
InstallNginx 2>&1 | tee -a logs/InstallNginx-`date +%Y%m%d`.log