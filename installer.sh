#!/bin/bash
# This is for CentOS 6.4 64bit
# MIGHT work on 5.4 64bit
#       [root@installertest ~]# ./install
#	Press enter to BEGIN ...
#
#	Installing seedbox please wait ...
#
#	Performing yum update ... [ DONE ]
#	Installing rpmforge ... [ DONE ]
#	Installing epel ... [ DONE ]
#	Installing CentOS Development tools ... [ DONE ]
#	Installing httpd, rtorrent, libtorrent, dejavu, subversion, yasm, nasm, screen, bwm-ng, unrar, xmlrpc-c, nano, php, mktorrent ... [ DONE ]
#	Setting up /etc/rssh.conf ... [ DONE ]
#	Installing ffmpeg for screenshots (This can take awhile depending on the system specs) ... [ DONE ]
#	Setting up seedbox.conf for apache ... [ DONE ]
#	Installing rutorrent into /srv ... [ DONE ]
#	Installing plugins ... [ DONE ]
#	Username: username
#	Password: (hit enter to generate a password) password
#	using password
#	Installing .rtorrent.rc for password ... [ DONE ]
#	Installing autodl-irssi ... [ DONE ]
#	Making black directory structure ... [ DONE ]
#	Writing black rtorrent.cron ... [ DONE ]
#	Setting permissions on black ... [ DONE ]
#	Writing username rutorrent config.php file ... [ DONE ]
#	Installing startup script ... [ DONE ]
#	Setting irssi/httpd/rtorrent to start on boot ... [ DONE ]
#	COMPLETED in 18/min
#       Seedbox can be found at http://lighttpd:QOXwEgspTm1TkAVh@192.168.0.2 (it will redirect to SSL by default)
#       [root@installertest ~]# cat install 
echo "Press enter to BEGIN ... "
read unusedvar
if [[ $EUID -ne 0 ]]; then
   echo "sorry $USER, you must be root..get root or get lost!" 
   exit 1
fi
if [[ ! -f /etc/centos-release ]];then echo "this is designed for centos ... exiting";exit 0;fi

S=`date +%s`
genpass=`perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 15`
htpasswd="/etc/httpd/conf.d/htpasswd"
rutorrent="/srv/rutorrent/"
realm="rutorrent"
echo "Do not hit any keys during the install, they keys you press before you are"
echo "required to, it will/can be used as the username. So wait for the username"
echo "promt before you hit any keys"
echo ""
echo ""
echo "Installing seedbox please wait ..."
echo ""
OK=`echo -e "[ \e[0;32mDONE\e[00m ]"`
ip=`/sbin/ifconfig | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'|grep -v "^127"|head -n1`
echo -n "Performing yum update ... "
yum -y update >/dev/null 2>&1
echo $OK
# SETTING LANAGUAGE
echo -n "Setting language to en_US ... "
rm -rf /etc/sysconfig/i18n
cat >>/etc/sysconfig/i18n<<LAN
LANG="en_US.UTF-8"
SYSFONT="latarcyrheb-sun16"
LAN
source /etc/sysconfig/i18n reload
echo $OK
# INSTALL FOR RPMFORGE
echo -n "Installing rpmforge ... "
rpm -Uvh http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm >/dev/null 2>&1
rpm --import http://dag.wieers.com/rpm/packages/RPM-GPG-KEY.dag.txt >/dev/null 2>&1
echo $OK

# INSTALL FOR EPEL
echo -n "Installing epel ... "
rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm >/dev/null 2>&1
echo $OK

# INSTALLING DEVELOPMENT TOOLS REQUIRED TO BUILD FFMPEG
echo -n "Installing CentOS Development tools ... "
yum -y groupinstall "Development Tools" > /dev/null 2>&1
echo $OK

# THE GUTS FOR THE WHOLE THING
echo -n "Installing httpd, rtorrent, libtorrent, dejavu, subversion, yasm, nasm, screen, bwm-ng, unrar, xmlrpc-c, nano, php, mktorrent ... "
yum -y install php mod_ssl git irssi rssh cppunit-devel libsigc++20-devel.i686 libsigc++20-devel.x86_64 libcurl-devel xmlrpc-c-devel.i686 xmlrpc-c-devel.x86_64>/dev/null 2>&1
yum -y install php-pecl-geoip iotop bc unrar dejavu-sans-mono-fonts-2.30-2.el6.noarch dejavu-fonts-common dejavu-lgc-sans-mono-fonts-2.30-2.el6.noarch dejavu-fonts-common-2.30-2.el6.noarch subversion fontconfig fontconfig-devel mktorrent yasm nasm mod_ssl openssl php rtorrent libtorrent xmlrpc-c screen nano bwm-ng ifstat htop >/dev/null 2>&1
yum --disablerepo=rpmforge -y install perl-Time-HiRes perl-Archive-Zip perl-Net-SSLeay perl-HTML-Parser perl-XML-LibXML perl-Digest-SHA1 perl-JSON perl-JSON-XS perl-XML-LibXSLT >/dev/null 2>&1
rpm -Uhv http://downloads.sourceforge.net/mediainfo/mediainfo-0.7.56-1.x86_64.CentOS_6.rpm>/dev/null 2>&1
yum -y downgrade libtorrent >/dev/null 2>&1
yum clean all >/dev/null 2>&1
rpm -iUv http://downloads.sourceforge.net/zenlib/libzen0-0.4.26-1.x86_64.CentOS_6.rpm>/dev/null 2>&1
rpm -iUv http://downloads.sourceforge.net/mediainfo/libmediainfo0-0.7.56-1.x86_64.CentOS_6.rpm>/dev/null 2>&1
rpm -iUv http://downloads.sourceforge.net/mediainfo/mediainfo-0.7.56-1.x86_64.CentOS_6.rpm>/dev/null 2>&1
wget -q http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz>/dev/null 2>&1
gunzip GeoLiteCity.dat.gz>/dev/null 2>&1
mkdir -p /usr/share/GeoIP>/dev/null 2>&1
mv GeoLiteCity.dat /usr/share/GeoIP/GeoIPCity.dat>/dev/null 2>&1
echo $OK

# SETTING UP FOR CHROOT USING RSSH
echo -n "Setting up /etc/rssh.conf ... "
cat >/etc/rssh.conf<<RSS
logfacility = LOG_USER
allowscp
allowsftp
#allowcvs
#allowrdist
#allowrsync
umask = 022
chrootpath = /usr/local/chroot
user=exampleuser:011:00011:/usr/local/chroot
RSS
echo $OK

# AND HERE IS WHERE THE DEVELOPMENT TOOLS IS USED
echo -n "Building ffmpeg form source for screenshots ... "
cd /tmp
git clone git://source.ffmpeg.org/ffmpeg.git ffmpeg >/dev/null 2>&1
cd ffmpeg
export FC_CONFIG_DIR=/etc/fonts
export FC_CONFIG_FILE=/etc/fonts/fonts.conf
./configure --enable-libfreetype --enable-filter=drawtext --enable-fontconfig >/dev/null 2>&1
make >/dev/null 2>&1
make install >/dev/null 2>&1
cp /usr/local/bin/ffmpeg /usr/bin >/dev/null 2>&1
cp /usr/local/bin/ffprobe /usr/bin >/dev/null 2>&1
rm -rf /tmp/ffmpeg >/dev/null 2>&1
echo $OK

# BUILD VIRTUALHOST FOR SEEDBOX/RUTORRENT
echo -n "Setting up seedbox.conf for apache ... "
cat >/etc/httpd/conf.d/seedbox.conf<<EOF
LoadModule ssl_module modules/mod_ssl.so
Listen 443
SSLPassPhraseDialog  builtin
SSLSessionCache         shmcb:/var/cache/mod_ssl/scache(512000)
SSLSessionCacheTimeout  300
SSLMutex default
SSLRandomSeed startup file:/dev/urandom  256
SSLRandomSeed connect builtin
SSLCryptoDevice builtin
<VirtualHost *:80>
    ServerAdmin lamer@lamer.com
    ServerName ${ip}
    Redirect / https://${ip}
</VirtualHost>
<VirtualHost ${ip}:443>
        DocumentRoot "/srv/rutorrent/"
        <Directory "/srv/rutorrent/">
                Options Indexes FollowSymLinks
                AllowOverride All AuthConfig
                Order allow,deny
                Allow from all
        AuthType Digest
        AuthName "rutorrent"
        AuthUserFile '/etc/httpd/conf.d/htpasswd'
        Require valid-user
        </Directory>
        SSLEngine on
        SSLProtocol all -SSLv2
        SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM:+LOW
        SSLCertificateFile /etc/pki/tls/certs/localhost.crt
        SSLCertificateKeyFile /etc/pki/tls/private/localhost.key
        SetEnvIf User-Agent ".*MSIE.*" \
                 nokeepalive ssl-unclean-shutdown \
                 downgrade-1.0 force-response-1.0
</VirtualHost>
EOF

rm -rf /etc/httpd/conf.d/welcome.conf
rm -rf /etc/httpd/conf.d/ssl.conf
echo $OK

# INSTALLING RUTORRENT
echo -n "Installing rutorrent into /srv ... "
cd /srv
svn -q co http://rutorrent.googlecode.com/svn/trunk/rutorrent
echo $OK

# INSTALLING RUTORRENT PLUGINS
echo -n "Installing plugins ... "
cd ${rutorrent}plugins
for i in cpuload data diskspace erasedata rpc seedingtime theme tracklabels trafic unpack _getdir rssurlrewrite; do
svn -q co http://rutorrent.googlecode.com/svn/trunk/plugins/$i
done
svn -q co http://svn.rutorrent.org/svn/filemanager/trunk/fileshare
svn -q co http://rutorrent-logoff.googlecode.com/svn/trunk/ logoff
svn -q co https://github.com/zebraxxl/rutorrentMobile >/dev/null
svn -q co http://svn.rutorrent.org/svn/filemanager/trunk/filemanager >/dev/null
svn -q co https://svn.code.sf.net/p/autodl-irssi/code/trunk/rutorrent/autodl-irssi

cat >${rutorrent}/plugins/filemanager/scripts/screens<<'DUR'
#!/bin/bash
if [ ! -d "$2" ]; then
mkdir --mode=0777 -p "$2" || { echo "FATAL ERROR: temp dir creation failed"; exit; }
fi
echo "$$" > "$2/pid";
if [ ! -w "${4%/*}" ]; then
echo "1: FATAL ERROR: Destination ${4%/*} not permitted" >> "$2/log"; 
else
START=$(date +%s.%N)
"$1" -i "$3" -an -vf drawtext="timecode='00\:00\:00\:00' :rate=24 :fontcolor=white :fontsize=21 :shadowcolor=black :x=5 :y=5",scale="min($6\, iw*3/2):-1",select="not(mod(n\,$5)),tile=$8x$7" -vsync 0 -frames:v 1 "$4" 2>&1 | sed -u 's/^/0:  /' >> "$2/log"
END=$(date +%s.%N)
DIFF=$(echo "$END - $START" | bc)
echo "1: Done " >> "$2/log"
RUNTIME=$(echo $DIFF|cut -d. -f1)
echo "1: Generation time: $RUNTIME seconds">> "$2/log"
fi
sleep 20
rm -rf "$2"
DUR

svn co http://svn.rutorrent.org/svn/filemanager/trunk/filemanager >/dev/null 2>&1
list="edit-3.5.tar.gz \
	nfo-3.5.tar.gz \
	_noty-3.5.tar.gz \
	_getdir-3.5.tar.gz \
	ss-3.5.tar.gz \
        _task-3.5.tar.gz \
	ipad-3.5.tar.gz \
	filedrop-3.5.tar.gz \
        create-3.5.tar.gz \
	check_port-3.5.tar.gz \
	mediainfo-3.5.tar.gz \
        loginmgr-3.5.tar.gz \
	ratio-3.5.tar.gz \
	source-3.5.tar.gz \
        rutracker_check-3.5.tar.gz \
	rss-3.5.tar.gz \
	history-3.5.tar.gz \
        retrackers-3.5.tar.gz \
	autotools-3.5.tar.gz \
	screenshots-3.5.tar.gz \
	geoip-3.5.tar.gz"
for i in $list;do
wget -q https://rutorrent.googlecode.com/files/$i
tar -zxvf $i >/dev/null 2>&1
rm -rf $i >/dev/null 2>&1
done
wget https://github.com/geekism/rtorrent/raw/master/stream.tar >/dev/null 2>&1
tar -xvf stream.tar >/dev/null 2>&1
rm -rf stream.tar >/dev/null 2>&1

sed -i 's/showhidden: true,/showhidden: false,/g' ${rutorrent}plugins/filemanager/init.js
chown -R apache.apache $rutorrent
cat >${rutorrent}plugins/filemanager/conf.php<<'FM'
<?php
$fm['tempdir'] = '/tmp';               // path were to store temporary data ; must be writable 
$fm['mkdperm'] = 755;          // default permission to set to new created directories
$pathToExternals['rar'] = '/usr/bin/unrar';
$pathToExternals['zip'] = '/usr/bin/zip';
$pathToExternals['unzip'] = '/usr/bin/unzip';
$pathToExternals['tar'] = '/bin/tar';
$fm['archive']['types'] = array('rar', 'zip', 'tar', 'gzip', 'bzip2');
$fm['archive']['compress'][0] = range(0, 5);
$fm['archive']['compress'][1] = array('-0', '-1', '-9');
$fm['archive']['compress'][2] = $fm['archive']['compress'][3] = $fm['archive']['compress'][4] = array(0);
?>
FM
cat >${rutorrent}plugins/screenshots/conf.php<<SS
<?php
\$pathToExternals['ffmpeg'] = '';
\$extensions = array
(
        "3g2","3gp","4xm","iff","iss","mtv","roq","a64","ac3","anm","apc","asf","avi","avm2","avs","bethsoftvid",
        "bink","c93","cavsvideo","cdg","dirac","dnxhd","dsicin","dts","dv","dv1394","dvd","ea","eac3","ffm","film_cpk",
        "filmstrip","flic","flv","gxf","h261","h263","h264","idcin","image2","image2pipe",
        "ingenient","ipmovie","ipod","iv8","ivf","m4v","matroska","mjpeg","mov","m4a","mj2",
        "mp2","mp4","mpeg","mpeg1video","mpeg2video","mpegts","mpegtsraw","mpegvideo",
        "msnwctcp","mvi","mxf","mxf_d10","nc","nsv","nuv","ogg","psp","psxstr","rawvideo","rm","rpl","rtsp",
        "smk","svcd","swf","vcd","video4linux","video4linux2","vob","webm","wmv",
        "mkv","ogm","mpg","mpv","m1v","m2v","mp2","qt","rmvb","dat","ts"
);

?>
SS
chown -R apache.apache /srv/
echo $OK

# THIS IS WHERE YOU MAKE YOUR USER
echo -n "Username: "
read username
adduser $username -s /usr/bin/rssh

echo -n "Password: (hit enter to generate a password) "
read password

if [[ ! -z "$password" ]]; then
        echo "setting password to $password"
        passwd=${password}
        echo "$genpass" | (passwd --stdin $username >/dev/null 2>&1)
        (echo -n "$username:$realm:" && echo -n "$username:$realm:$genpass" | md5sum | awk '{print $1}' ) >> $htpasswd
else
        echo "setting password to $genpass"
        passwd=${genpass}
        echo "$password" | (passwd --stdin $username >/dev/null 2>&1)
        (echo -n "$username:$realm:" && echo -n "$username:$realm:$password" | md5sum | awk '{print $1}' ) >> $htpasswd
fi

PORT=$((RANDOM%64025+1024))
PORTEND=$(($PORT + 1500))
echo -n "Installing .rtorrent.rc for $username ... "
cat >/home/$username/.rtorrent.rc<<EOF
scgi_local = /home/$username/.rtorrent.rpc
min_peers = 50
max_peers = 200
min_peers_seed = 10
max_peers_seed = 50
max_uploads = 15
download_rate = 0
upload_rate = 0
directory = /home/$username/torrents/
session = /home/$username/.sessions/
schedule = watch_directory,5,5,load_start=/home/$username/watch/*.torrent
schedule = low_diskspace,5,60,close_low_diskspace=200M
port_range = $PORT-$PORTEND
check_hash = no
use_udp_trackers = yes
encryption = allow_incoming,enable_retry,prefer_plaintext
dht = off
peer_exchange = no
ratio.enable=
ratio.min.set=490
ratio.max.set=501
ratio.upload.set=600M
schedule = chmod,0,0,"execute=chmod,777,/home/$username/.rtorrent.rpc"
system.method.set = group.seeding.ratio.command, d.close=, d.erase=,"execute={rm,-rf,--,\$d.get_base_path=}"
system.method.set_key = event.download.erased, remove_file,"execute={rm,-drf,--,\$d.get_base_path=}"
EOF
echo $OK

echo -n "Setting up stream plugin ... "
cat >${rutorrent}plugins/stream/config.php<<'ST'
<?php
$auth = '';
define('USE_NGINX', false);
define('SCHEME', 'https');
ST
echo $OK

# INSTALLING AUTODL-IRSSI
echo -n "Installing autodl-irssi ... "
mkdir -p /home/$username/.irssi/ >/dev/null 2>&1
cd /home/$username/.irssi/ >/dev/null 2>&1
svn -q export https://svn.code.sf.net/p/autodl-irssi/code/trunk/src scripts
mkdir /home/$username/.irssi/scripts/autorun >/dev/null 2>&1
cp /home/$username/.irssi/scripts/autodl-irssi.pl /home/$username/.irssi/scripts/autorun/
mkdir -p /home/$username/.autodl >/dev/null 2>&1
echo "user=$username:011:00011:/home/$username">>/etc/rssh.conf
cat >/home/$username/.autodl/autodl.cfg<<ADC
[options]
gui-server-port = $IRSSI_PORT
gui-server-password = $IRSSI_PASS
allowed = watchdir
ADC
chown -R $username.$username /home/$username/.irssi/
chown -R $username.$username /home/$username
echo $OK

# CREATING USER DIRECTORY
echo -n "Making $username directory structure ... "
mkdir /home/$username/{torrents,.sessions,watch} >/dev/null 2>&1
chown $username.apache /home/$username/{torrents,.sessions,watch,.rtorrent.rc} >/dev/null 2>&1
usermod -a -G apache $username >/dev/null 2>&1
usermod -a -G $username apache >/dev/null 2>&1
echo $OK

# WRITING CRON FOR AUTOLOADING irssi APON CRASHING
echo -n "Writing $username irssi.cron ... "

cat >/home/$username/irssi.cron<<EOF
#!/bin/sh
procname=/usr/bin/irssi
sessionname='irssi'
runcmd="screen -fa -dmS \$sessionname \$procname"
username=\`id -un\`
existing_pids=\`/sbin/pidof -s \$procname\`
if [ -z \$existing_pids ];
then
        startproc=true;
else
    	my_pid=\`ps -U $username -u $username -o pid= | grep "\$existing_pids"\`;
        if [ -z \$my_pid ]; then startproc=true; fi
fi
if [ ! -z \$startproc ];
then
	\$runcmd;
fi
EOF
chmod +x /home/$username/irssi.cron
echo $OK

# WRITING AUTORELOAD CRON FOR RTORRENT
echo -n "Writing $username rtorrent.cron ... "
cat >/home/$username/rtorrent.cron<<EOF
#!/bin/bash
HOME="/home/$username"
PROGRAM="/usr/bin/rtorrent"
GRACE_DELAY=5
while true;
do
    rm -rf \$HOME/.rtorrent.rpc
    "\$PROGRAM"
    RETURNED=\$?
    if [ \$RETURNED -ne 0 ]
    then
  echo "\$PROGRAM did not exit cleanly with status code \$RETURNED"
  echo "pausing for \$GRACE_DELAY seconds before restarting \$PROGRAM"
  sleep \$GRACE_DELAY;
    else
  echo "\$PROGRAM exited cleanly. It will not be restarted automatically"
  exit 0
    fi
done
EOF
echo $OK

# SETTING PERMISSIONS JUST INCASE
echo -n "Setting permissions on $username ... "
chown -R $username.$username /home/$username/ >/dev/null 2>&1
sudo -u $username chmod +x /home/$username/rtorrent.cron >/dev/null 2>&1
sudo -u $username chmod +x /home/$username/irssi.cron >/dev/null 2>&1
sudo -u $username chmod 755 /home/$username/ >/dev/null 2>&1
echo $OK
echo -n "Starting irssi/rtorrent for $username ... "
sudo -u $username /usr/bin/screen -fa -d -m -s torrent /home/$username/rtorrent.cron >/dev/null 2>&1
sudo -u $username /usr/bin/screen -fa -d -m -S irssi irssi
mkdir /srv/rutorrent/conf/users/$username >/dev/null 2>&1
echo $OK

# WRITING USER CONFIG.PHP
echo -n "Writing $username rutorrent config.php file ... "
IRSSI_PASS=`perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 15`
IRSSI_PORT=$((RANDOM%64025+1024))
cat >${rutorrent}conf/users/$username/config.php<<EOF
<?php
  @define('HTTP_USER_AGENT', 'Mozilla/5.0 (Windows NT 6.0; WOW64; rv:12.0) Gecko/20100101 Firefox/12.0', true);
  @define('HTTP_TIME_OUT', 30, true);
  @define('HTTP_USE_GZIP', true, true);
  \$httpIP = null;
  @define('RPC_TIME_OUT', 5, true);
  @define('LOG_RPC_CALLS', false, true);
  @define('LOG_RPC_FAULTS', true, true);
  @define('PHP_USE_GZIP', false, true);
  @define('PHP_GZIP_LEVEL', 2, true);
  \$schedule_rand = 10;
  \$do_diagnostic = true;
  \$log_file = '/tmp/errors.log';
  \$saveUploadedTorrents = true;
  \$overwriteUploadedTorrents = false;
  \$topDirectory = '/home/$username/';
  \$forbidUserSettings = false;
  \$scgi_port = 0;
  \$scgi_host = "unix:///home/$username/.rtorrent.rpc";
  \$XMLRPCMountPoint = "/RPC2";
  \$pathToExternals = array("php" => '',"curl" => '',"gzip" => '',"id" => '',"stat" => '',);
  \$localhosts = array("127.0.0.1", "localhost",);
  \$profilePath = '../share';
  \$profileMask = 0777;
  \$autodlPort = $IRSSI_PORT;
  \$autodlPassword = "$IRSSI_PASS";
EOF
chown -R apache.apache /srv/rutorrent/conf/users/ >/dev/null 2>&1
echo $OK

# INSTALLING START UP SCRIPT FOR RTORRENT
echo -n "Installing startup script ... "
cat >/etc/init.d/rtorrent<<'ITD'
#!/bin/sh
#
# rtorrent          Start/Stop the rtorrent clock daemon.
#
# chkconfig: 2345 90 60
# description: rtorrent is a standard UNIX program that runs user-specified torrents

### BEGIN INIT INFO
# Provides: rtorrent
# Required-Start: $local_fs $syslog
# Required-Stop: $local_fs $syslog
# Default-Start:  2345
# Default-Stop: 90
# Short-Description: run rtorrent daemon
# Description: rtorrent is a torrent client
### END INIT INFO

USERS=`awk -F: '{print $1}' /etc/httpd/conf.d/htpasswd`
case "$1" in
    start)
        for i in $USERS; do
                if [[ ! `ps aux|grep -E "$i"|grep -v grep|grep "/bin/bash /home/$i/rtorrent.cron"|awk '{print $2}'` -gt 5 ]]; then
                        sudo -u $i /usr/bin/screen -fa -d -m -S rtorrent /home/$i/rtorrent.cron
                fi
        done
        ;;
    stop)
        for i in $USERS; do
        uid=`id $i|cut -d'=' -f2|awk -F( '{print $1}'`
                PID=`ps aux|grep -E "$i|$uid"|grep -v grep|grep "/usr/bin/SCREEN -fa -d -m -S rtorrent /home/$i/rtorrent.cron"|awk '{print $2}'`
                kill -9 $PID
        done
        ;;
    check-users|status)
        for i in $USERS; do
        uid=`id $i|cut -d'=' -f2|awk -F( '{print $1}'`
                if [[ ! `ps aux|grep -E "$i|$uid"|grep -v grep|grep "/bin/bash /home/$i/rtorrent.cron"|awk '{print $2}'` -gt 5 ]]; then 
                        sudo -u $i /usr/bin/screen -fa -d -m -S rtorrent /home/$i/rtorrent.cron
                fi
        done
        ;;
    reload-config)
        for i in $USERS;do
        uid=`id $i|cut -d'=' -f2|awk -F( '{print $1}'`
                PID=`ps aux|grep -E "$i|$uid"|grep -v grep|grep "bin/rtorrent"|awk '{print $2}'`
                kill -9 $PID
        done
        ;;
    restart)
        for i in $USERS; do
        uid=`id $i|cut -d'=' -f2|awk -F( '{print $1}'`
                PID=`ps aux|grep -E "$i|$uid"|grep -v grep|grep "/usr/bin/SCREEN -fa -d -m -S torrent /home/$i/rtorrent.cron"|awk '{print $2}'`
                kill -9 $PID
                sudo -u $i /usr/bin/screen -fa -d -m -S rtorrent /home/$i/rtorrent.cron
        done
        ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|reload-config|check-users}"
        exit 2
esac
exit $?
ITD
echo $OK
echo -n "Fetching newuser.sh chgpass.sh to /root ... "
cd
wget -q https://raw.github.com/geekism/rtorrent/master/chgpass
wget -q https://raw.github.com/geekism/rtorrent/master/newuser.sh -Onewuser
chmod +x newuser
chmod +x chgpass
cp newuser /usr/sbin
cp chgpass /usr/sbin
echo $OK

echo -n "Setting irssi/httpd/rtorrent to start on boot ... "
tmpfile="/tmp/`perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 8`"
touch $tmpfile
echo "@reboot /usr/bin/screen -fa -d -m -S rtorrent /home/$username/rtorrent.cron">>$tmpfile
echo "*/1 * * * * /home/$username/irssi.cron">>$tmpfile
sudo -u $username crontab $tmpfile
rm -rf $tmpfile
service httpd restart >/dev/null 2>&1
chkconfig httpd on
chmod +x /etc/init.d/rtorrent
chkconfig rtorrent on
echo $OK
E=`date +%s`
DIFF=`expr $E - $S`
FIN=`expr $DIFF / 60`
sed -i 's/RPM-GPG-KEY-rpmforge-dag/RPM-GPG-KEY-rpmforge-dag\nexclude=libtorrent/' /etc/yum.repos.d/rpmforge.repo
sed -i 's/RPM-GPG-KEY-EPEL-6/RPM-GPG-KEY-EPEL-6\nexclude=libtorrent/' /etc/yum.repos.d/epel.repo
echo "COMPLETED in ${FIN}/min"
echo "Seedbox can be found at http://${username}:${passwd}@$ip (it will redirect to SSL by default)"
