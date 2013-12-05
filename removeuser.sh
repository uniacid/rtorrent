#!/bin/bash                                                                                                                                                  
OK=`echo -e \"\[ \\\\e[0\;32mOK\\\\e[00m \]\"`                                                                                                               
seed=`perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 5`
htpasswd="/etc/httpd/conf.d/htpasswd"; 
ruconf="/srv/rutorrent/conf/users";
echo -n "Username: "
read username
echo -n "Removing ${username} ... "
for i in `ps -U ${username}|grep "[0-9]"|awk '{print $1}'`;do kill -9 $i >/dev/null 2>&1 ;done 
grep -v "^${username}" ${htpasswd} > /tmp/${seed} 
mv /tmp/${seed} ${htpasswd} >/dev/null 2>&1
rm -rf ${ruconf}/${username} >/dev/null 2>&1
rm -rf /home/${username} >/dev/null 2>&1
rm -rf /var/run/screen/S-${username} >/dev/null 2>&1
rm -rf ${ruconf}/../share/users/${username} >/dev/null 2>&1
rm -rf ${ruconf}/../share/users/black/settings/chat >/dev/null 2>&1
cat /etc/fstab | grep -vE "home_bolded|home/${username}" > /tmp/${seed}
mv /tmp/${seed} /etc/fstab
grep -v "user=${username}:" /etc/rssh.conf > /tmp/${seed}
mv /tmp/${seed} /etc/rssh.conf
userdel -r ${username}
groupdel ${username}
rm -rf /var/mail/${username}
echo $OK
