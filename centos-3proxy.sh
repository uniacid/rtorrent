ip=`/sbin/ifconfig | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'|grep -v "^127"|head -n1`
genpass=`perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 8`
OK=`echo -e "[ \e[0;32mDONE\e[00m ]"`
echo -n "Installing 3Proxy ... "
mkdir /tmp/proxy
        cd /tmp/proxy
        wget http://www.3proxy.ru/0.6.1/3proxy-0.6.1.tgz >/dev/null 2>&1
        tar -xzf 3proxy-0.6.1.tgz 
        rm 3proxy-0.6.1.tgz
        cd 3proxy-0.6.1
        yum -y groupinstall "Development Tools" >/dev/null 2>&1
        make -f Makefile.Linux
cd src
        mkdir /etc/3proxy/
mv 3proxy /etc/3proxy/
        cd /etc/3proxy/
touch /etc/3proxy/3proxy.cfg
cat > "/etc/3proxy/3proxy.cfg" <<END
daemon
nserver 8.8.8.8
nserver 8.8.4.4
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
users proxy:CL:$genpass
service
#log /var/log/3proxy.log D
#logformat "- +_L%t.%.  %N.%p %E %U %C:%c %R:%r %O %I %h %T"
#archiver rar rar a -df -inul %A %F
#rotate 30
external $ip
internal $ip
auth none
#dnspr
#deny * * 127.0.0.1,192.168.1.1
allow * * * 80-88,8080-8088 HTTP
allow * * * 443,8443 HTTPS
proxy -p24019 -n
socks -p24018 
flush
allow * * *
maxconn 20
flush
internal 127.0.0.1
allow 3APA3A 127.0.0.1
maxconn 3
pidfile /var/run/3proxy.pid
#admin

END
chmod 600 /etc/3proxy/3proxy.cfg
touch /etc/init.d/3proxy
        chmod  +x /etc/init.d/3proxy
        cat > "/etc/init.d/3proxy" <<'END'
#!/bin/sh
#
# 3proxy server
#
# chkconfig:   - 35 65
# description: 3proxys

### BEGIN INIT INFO
# Provides: identd
# Required-Start: $local_fs $network
# Required-Stop: $local_fs $network
# Should-Start: 
# Should-Stop: 
# Default-Start: 
# Default-Stop: 0 1 2 3 4 5 6
# Short-Description: 3proxy-server
# Description:       3proxy
### END INIT INFO


case "$1" in
   start)
       echo Starting 3Proxy;/etc/3proxy/3proxy /etc/3proxy/3proxy.cfg
       ;;
   stop)
       echo Stopping 3Proxy;/usr/bin/killall 3proxy
       ;;
   restart|reload)
       echo Reloading 3Proxy;/usr/bin/killall -s USR1 3proxy
       ;;
   *)
       echo Usage: $0 "{start|stop|restart}"
       exit 1
esac
exit 0
END
echo $OK
echo "3Proxy installed, Username: proxy, password: $genpass, IP used: $ip Socks: 24018 HTTP Proxy: 24019"
