#! /bin/sh
 
#Process_Name="/yshd
Process_Name="/yshd"
#获取主机IP地址
ip=`ifconfig eth0 |grep "inet addr"| cut -f 2 -d ":"|cut -f 1 -d " "`
gstr="/yshd"
space=" "
First_Process=""
 
#获取初始业务进程号
for i in $Process_Name
do
    if [[ $i == $gstr ]]
    then
        Bf_Process=`ps |grep $i|grep -v grep|grep -v '/bin/bash'|awk '{print $1}'`
        First_Process=$First_Process$i":"$Bf_Process$space
    else
        Bf_Process=`ps |grep $i|grep -v grep|awk '{print $1}'`
        First_Process=$First_Process$i":"$Bf_Process$space
    fi
done
 
while true
do
    For_num=1
    sleep 3
    Second_Process=""
    #第二次获取业务进程号
    for i in $Process_Name
    do
        if [[ $i == $gstr ]]
        then
            Bs_Process=`ps |grep $i|grep -v grep|grep -v '/bin/bash'|awk '{print $1}'`
            Second_Process=$Second_Process$i":"$Bs_Process$space
        else
            Bs_Process=`ps |grep $i|grep -v grep|awk '{print $1}'`
            Second_Process=$Second_Process$i":"$Bs_Process$space
        fi
    done
    echo "First_Process:"$First_Process
    echo "Second_Process:"$Second_Process
    #查看所有业务进程有无变化，有变化输出到日志文件
    for j in $Process_Name
    do
        echo $j
        One_f_Process=`echo $First_Process|awk -v t="${For_num}" '{print $t}'`
        One_s_Process=`echo $Second_Process|awk -v t="${For_num}" '{print $t}'`
        For_num=$((For_num+1))
        echo "One_f_Process:"$One_f_Process
        echo "One_s_Process:"$One_s_Process
        if [[ "$One_f_Process" != "$One_s_Process" ]]
        then
            Time_Now=`date`
            echo $Time_Now
            echo $j
            echo $One_s_Process
            echo $One_f_Process
            echo -e $Time_Now"\t"$j"\tCollapse\tThe new process："$One_s_Process"\t\tThe old process："$One_f_Process >> /usr/tmp/$ip'_collapse'.txt
        fi
    done
    #获取业务进程号
    First_Process=""
    for i in $Process_Name
    do
        if [[ $i == $gstr ]]
        then
            Bf_Process=`ps |grep $i|grep -v grep|grep -v '/bin/bash'|awk '{print $1}'`
            First_Process=$First_Process$i":"$Bf_Process$space
        else
            Bf_Process=`ps |grep $i|grep -v grep|awk '{print $1}'`
            First_Process=$First_Process$i":"$Bf_Process$space
        fi
    done
     
    #系统内存使用率监控
    Memory_Use_Rate=`free | grep Mem | awk '{printf"%d",$3/$2*100}'`
    if [ 80 -le $Memory_Use_Rate ]
    then
        Time_Now=`date`
        echo -e $Time_Now"\tSystm Memory\tMemory_Use_Rate\tAt present the use value:"$Memory_Use_Rate"%\tThreshold:80%" >> /usr/tmp/$ip'_alarm'.txt
    fi
     
    #系统CPU剩余率监控
    Cpu_Residual_Rate=`mpstat|grep all|awk '{printf"%d",$11}'`
    echo $Cpu_Residual_Rate
    if [ $Cpu_Residual_Rate -le 20 ]
    then
        Time_Now=`date`
        echo $Time_Now
        echo -e $Time_Now"\tSystm Cpu\tCpu_Residual_Rate(%idle)\tAt present the use value:"$Cpu_Residual_Rate"%\tThreshold:20%" >> /usr/tmp/$ip'_alarm'.txt
    fi 
     
    #业务内存使用率监控
    System_Memory=`free | grep Mem | awk '{printf"%d",$2/1024}'`
    for k in $Process_Name
    do
        if [[ $k == $gstr ]]
        then
            Process_Memory_Use=`ps |grep $k|grep -v grep|grep -v '/bin/bash'|awk '{print $3}'`
            var_length=${#Process_Memory_Use}
            var_Position=`expr $var_length - 1`
            m=${Process_Memory_Use:$var_Position:1}
            if [[ $m == "m" ]]
            then
                Pro_Mem_Use=${Process_Memory_Use:0:$var_Position}   
            else
                Pro_Mem_Use=`expr $Process_Memory_Use / 1024`
            fi
            System_Memory_Threshold=`free | grep Mem | awk '{printf"%d",$2/1024*0.8}'`
            if [[ $Pro_Mem_Use  -ge $System_Memory_Threshold ]]
            then
                Time_Now=`date`
                echo -e $Time_Now"\t"$k"\tProcess_Memory_Use\tAt present the use value:"$Pro_Mem_Use"Mb\tThreshold:"$System_Memory_Threshold"Mb" >> /usr/tmp/$ip'_alarm'.txt
            fi
        else
            Process_Memory_Use=`ps |grep $k|grep -v grep|awk '{print $3}'`
            var_length=${#Process_Memory_Use}
            var_Position=`expr $var_length - 1`
            m=${Process_Memory_Use:$var_Position:1}
            if [[ $m == "m" ]]
            then
                Pro_Mem_Use=${Process_Memory_Use:0:$var_Position}   
            else
                Pro_Mem_Use=`expr $Process_Memory_Use / 1024`
            fi
            System_Memory_Threshold=`free | grep Mem | awk '{printf"%d",$2/1024*0.8}'`
            if [[ $Pro_Mem_Use  -ge $System_Memory_Threshold ]]
            then
                Time_Now=`date`
                echo -e $Time_Now"\t"$k"\tProcess_Memory_Use\tAt present the use value:"$Pro_Mem_Use"Mb\tThreshold:"$System_Memory_Threshold"Mb" >> /usr/tmp/$ip'_alarm'.txt
            fi
        fi
    done
done