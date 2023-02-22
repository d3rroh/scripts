#!/bin/bash
S="************************************"
D="-------------------------------------"
COLOR="y"

MOUNT=$(mount|egrep -iw "ext4|ext3|xfs|gfs|gfs2|btrfs"|grep -v "loop"|sort -u -t' ' -k1,2)
FS_USAGE=$(df -PThl -x tmpfs -x iso9660 -x devtmpfs -x squashfs|awk '!seen[$1]++'|sort -k6n|tail -n +2)
IUSAGE=$(df -iPThl -x tmpfs -x iso9660 -x devtmpfs -x squashfs|awk '!seen[$1]++'|sort -k6n|tail -n +2)

if [ $COLOR == y ]; then
{
 GCOLOR="\e[47;32m ------ OK/HEALTHY \e[0m"
 WCOLOR="\e[43;31m ------ WARNING \e[0m"
 CCOLOR="\e[47;31m ------ CRITICAL \e[0m"
}
else
{
 GCOLOR=" ------ OK/HEALTHY "
 WCOLOR=" ------ WARNING "
 CCOLOR=" ------ CRITICAL "
}
fi

echo -e "$S"
echo -e "\tSystem Health Status"
echo -e "$S"

#--------Print Operating System Details--------#
hostname -f &> /dev/null && printf "Hostname : $(hostname -f)" || printf "Hostname : $(hostname -s)"

echo -en "\nOperating System : "
[ -f /etc/os-release ] && echo $(egrep -w "NAME|VERSION" /etc/os-release|awk -F= '{ print $2 }'|sed 's/"//g') || cat /etc/system-release

echo -e "Kernel Version :" $(uname -r)
printf "OS Architecture :"$(arch | grep x86_64 &> /dev/null) && printf " 64 Bit OS\n"  || printf " 32 Bit OS\n"

#--------Print system uptime-------#
UPTIME=$(uptime)
echo -en "System Uptime : "
echo $UPTIME|grep day &> /dev/null
if [ $? != 0 ]; then
  echo $UPTIME|grep -w min &> /dev/null && echo -en "$(echo $UPTIME|awk '{print $2" by "$3}'|sed -e 's/,.*//g') minutes" \
 || echo -en "$(echo $UPTIME|awk '{print $2" by "$3" "$4}'|sed -e 's/,.*//g') hours"
else
  echo -en $(echo $UPTIME|awk '{print $2" by "$3" "$4" "$5" hours"}'|sed -e 's/,//g')
fi
echo -e "\nCurrent System Date & Time : "$(date +%c)

#--------Check for any read-only file systems--------#
echo -e "\nChecking For Read-only File System[s]"
echo -e "$D"
echo "$MOUNT"|grep -w ro && echo -e "\n.....Read Only file system[s] found"|| echo -e ".....No read-only file system[s] found. "

#--------Check for Currently mounted file systems--------#
echo -e "\n\nChecking For Currently Mounted File System[s]"
echo -e "$D$D"
echo "$MOUNT"|column -t

#--------Check disk usage on all mounted file systems--------#
echo -e "\n\nChecking For Disk Usage On Mounted File System[s]"
echo -e "$D$D"
echo -e "( 0-85% = OK/HEALTHY,  85-95% = WARNING,  95-100% = CRITICAL )"
echo -e "$D$D"
echo -e "Mounted File System[s] Utilization (Percentage Used):\n"

COL1=$(echo "$FS_USAGE"|awk '{print $1 " "$7}')
COL2=$(echo "$FS_USAGE"|awk '{print $6}'|sed -e 's/%//g')

for i in $(echo "$COL2"); do
{
  if [ $i -ge 95 ]; then
    COL3="$(echo -e $i"% $CCOLOR\n$COL3")"
  elif [[ $i -ge 85 && $i -lt 95 ]]; then
    COL3="$(echo -e $i"% $WCOLOR\n$COL3")"
  else
    COL3="$(echo -e $i"% $GCOLOR\n$COL3")"
  fi
}
done
COL3=$(echo "$COL3"|sort -k1n)
paste  <(echo "$COL1") <(echo "$COL3") -d' '|column -t

echo -e "\n\nPanel Installed"
echo -e "$D$D"
#--------Check for panel installed--------#
detect_cp() {
    CP_VERSION="Unknown"
    SOFTACULOUS=0
    if [ -d "/usr/local/cwp" ]; then
        CP="CWP Panel"
        CP_VERSION=`/usr/local/cwpsrv/htdocs/resources/admin/include/version.php| grep version`
        if [ -e "/usr/local/softaculous" ]; then SOFTACULOUS=1; fi
    fi
    if [ -d "/usr/local/cpanel/whostmgr/docroot/" ]; then
        CP="cPanel"
        CP_VERSION=`/usr/local/cpanel/cpanel -V`
        if [ -e "/usr/local/cpanel/whostmgr/cgi/softaculous" ]; then SOFTACULOUS=1; fi
    fi
    if [ -d "/usr/local/CyberPanel/" ]; then
        CP="Cyberpanel"
        CP_VERSION=`cyberpanel -v`
        if [ -e "/usr/local/softaculous" ]; then SOFTACULOUS=1; fi
    fi
    echo "Control Panel"
    echo "CP: $CP"
    echo "VERSION: $CP_VERSION"
    echo "SOFTACULOUS: $SOFTACULOUS"
    if [ -n "${CP_ISP_TYPE}" ]; then
        echo "ISP TYPE: ${CP_ISP_TYPE}"
    fi
}
detect_cp

#--------Webserver Status-----#
echo -e "\n\nWebserver Status"
echo -e "$D$D"

if systemctl is-active --quiet httpd; then
  echo "Apache is running"
else
  echo "Apache is not running"
fi

if systemctl is-active --quiet lscpd; then
  echo "Litespeed is running"
else
  echo "Litespeed is not running"
fi

if systemctl is-active --quiet nginx; then
  echo "Nginx is running"
else
  echo "Nginx is not running"
fi

#------MYSQL STATUS----#
echo -e "\nTop 5 Database Status"
echo -e "$D$D"

if systemctl is-active --quiet mysqld; then
  echo "mysqld is running"
else
  echo "mysqld is not running"
fi

if systemctl is-active --quiet mongod; then
  echo "MongoDB is running"
else
  echo "MongoDB is not running"
fi

#--------Exim Status--------#
echo -e "\n\nEXim and Postfix Status(Mails)"
echo -e "$D$D"
if systemctl is-active --quiet exim; then
  echo "Exim is running"
else
  echo "Exim is not running"
fi

if systemctl is-active --quiet postfix; then
  echo "postfix is running"
else
  echo "postfix is not running"
fi

if systemctl is-active --quiet dovecot; then
  echo "dovecot is running"
else
  echo "dovecot is not running"
fi

# Check the status of Exim

#--------Check for Processor Utilization (current data)--------#
echo -e "\n\nChecking For Processor Utilization"
echo -e "$D"
echo -e "\nCurrent Processor Utilization Summary :\n"
mpstat|tail -2

#--------Check for load average (current data)--------#
echo -e "\n\nChecking For Load Average"
echo -e "$D"
echo -e "Current Load Average : $(uptime|grep -o "load average.*"|awk '{print $3" " $4" " $5}')"


#--------Print top 5 Memory & CPU consumed process threads---------#
#--------excludes current running program which is hwlist----------#
echo -e "\n\nTop 5 Memory Resource Hog Processes"
echo -e "$D$D"
ps -eo pmem,pid,ppid,user,stat,args --sort=-pmem|grep -v $$|head -6|sed 's/$/\n/'
 
echo -e "\nTop 5 CPU Resource Hog Processes"
echo -e "$D$D"
ps -eo pcpu,pid,ppid,user,stat,args --sort=-pcpu|grep -v $$|head -6|sed 's/$/\n/'

echo -e "NOTE:- If any of the above fields are marked as \"blank\" or \"NONE\" or \"UNKNOWN\" or \"Not Available\" or \"Not Specified\"
that means either there is no value present in the system for these fields, otherwise that value may not be available,
or suppressed since there was an error in fetching details."
echo -e "\n\t\t %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
echo -e "\t\t   <>--------<> Powered By : TRUEHOST CLOUD <>--------<>"
echo -e "\t\t %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
