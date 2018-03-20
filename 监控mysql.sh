#!/bin/bash
#/usr/bin/nmap localhost | grep 3306
#lsof -i:3306
MYSQLPORT=`netstat -na|grep "LISTEN"|grep "3306"|awk -F[:" "]+ '{print $5}'`

function checkMysqlStatus(){
	/usr/bin/mysql -uroot -p11111 --connect_timeout=5 -e "show databases;" &>/dev/null 2>&1
	if [ $? -ne 0 ]
	then
		restartMysqlService
		if [ "$MYSQLPORT" == "3306" ];then
			echo "mysql restart successful......" 
		else
			echo "mysql restart failure......"
			echo "Server: $MYSQLIP mysql is down, please try to restart mysql by manual!" > /var/log/mysqlerr
			#mail -s "WARN! server: $MYSQLIP  mysql is down" server@shangtv.cn < /var/log/mysqlerr
		fi
	else
		echo "mysql is running..."
	fi
}

function restartMysqlService(){
	echo "try to restart the mysql service......"
	/bin/ps aux |grep mysql |grep -v grep | awk '{print $2}' | xargs kill -9
	service mysql start
}

if [ "$MYSQLPORT" == "3306" ]
then
	checkMysqlStatus
else
	restartMysqlService
fi