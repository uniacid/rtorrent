#!/bin/bash
# FOR USE WITH CHROOT RSSH SETUPS
OK=`echo -e "[\e[0;32mOK\e[00m]"`
realm="rutorrent" ;                                                     # realm name
htpasswd="/etc/httpd/conf.d/htpasswd";                                  # location of your realm file
genpass=`perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 15`
ruconf="/srv/rutorrent/conf/users";                             #location of your userfolder for rutorrent (no trailing slashes)
chroot="/usr/local/chroot"; #chroot directory (default dir)
IRSSI_PASS=`perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 15`
IRSSI_PORT=$((RANDOM%64025+1024))
echo -n "Username: "
  read username
  if grep -Fxq "$username" /etc/passwd; then
        echo "$username exists! cant proceed..."
        exit
  else
  useradd -s /usr/bin/rssh $username
echo -n "Password: (hit enter to generate a password) "
read password
        chown $username.apache /home/$username >/dev/null 2>&1
  cp $htpasswd /root/rutorrent-htpasswd.`date +'%d.%m.%y-%S'`
  if [[ "$password" == "" ]]; then
        echo "setting password to $genpass"
        echo "$genpass" | (passwd --stdin $username >/dev/null 2>&1)
        (echo -n "$username:$realm:" && echo -n "$username:$realm:$genpass" | md5sum | awk '{print $1}' ) >> $htpasswd
  else
        echo "using $password"
        echo "$password" | (passwd --stdin $username >/dev/null 2>&1)
        (echo -n "$username:$realm:" && echo -n "$username:$realm:$password" | md5sum | awk '{print $1}' ) >> $htpasswd
  fi
PORT=$(($RANDOM + ($RANDOM % 2) * 32768))
PORTEND=$(($PORT + 1500))
echo -n "writing $username .rtorrent.rc using port-range (${PORT}-${PORTEND})..."
cat >/home/$username/.rtorrent.rc<<EOF
scgi_local = /home/$username/.rtorrent.rpc
min_peers = 40
max_peers = 100
min_peers_seed = 10
max_peers_seed = 50
max_uploads = 15
download_rate = 0
upload_rate = 0
directory = /home/$username/torrents/
session = /home/$username/.sessions/
schedule = watch_directory,5,5,load_start=/home/$username/watch/*.torrent
schedule = low_diskspace,5,60,close_low_diskspace=2000M
port_range = $PORT-$PORTEND
check_hash = no
use_udp_trackers = yes
encryption = allow_incoming,enable_retry,prefer_plaintext
dht = off
peer_exchange = no
ratio.enable=1
ratio.min.set=500
schedule = chmod,0,0,"execute=chmod,777,/home/$username/.rtorrent.rpc"
EOF
echo $OK
echo -n "setting permissions ... "
  mkdir /home/$username/{torrents,.sessions,watch} >/dev/null 2>&1
  chown $username.apache /home/$username/{torrents,.sessions,watch,.rtorrent.rc} >/dev/null 2>&1
  usermod -a -G apache $username >/dev/null 2>&1
  usermod -a -G $username apache >/dev/null 2>&1
echo $OK
echo -n "writing $username rtorrent/irssi cron script ... "
cat >/home/$username/irssi.cron<<EOF
#!/bin/sh
procname=/usr/bin/irssi
sessionname='irssi'
runcmd="screen -dmS \$sessionname \$procname"
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
cat >/home/$username/cron<<EOT
  #!/bin/bash
  uhome="/home/$username"
  PROGRAM="/usr/bin/rtorrent"
  GRACE_DELAY=15
  while true;
  do
      rm -rf /\$HOME/.rtorrent.rpc
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
EOT
echo $OK
echo -n "enabling $username cron script ... "
  chown $username.$username /home/$username/cron >/dev/null 2>&1
  sudo -u $username chmod +x /home/$username/cron >/dev/null 2>&1
  sudo -u $username chmod 750 /home/$username/ >/dev/null 2>&1
  chown -R $username.apache /home/${username}
echo $OK
echo -n "writing $username rutorrent config.php ... "
  mkdir $ruconf/$username >/dev/null 2>&1
cat >$ruconf/$username/config.php<<DH
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
DH
echo $OK
chown -R apache.apache $ruconf >/dev/null 2>&1
fi
echo -n "Setting up autodl-irssi for $username ... "
mkdir -p /home/$username/.irssi/ >/dev/null 2>&1
cd /home/$username/.irssi/ >/dev/null 2>&1
svn -q export https://svn.code.sf.net/p/autodl-irssi/code/trunk/src scripts
mkdir /home/$username/.irssi/scripts/autorun >/dev/null 2>&1
cp /home/$username/.irssi/scripts/autodl-irssi.pl /home/$username/.irssi/scripts/autorun/
mkdir -p /home/$username/.autodl >/dev/null 2>&1
cat >/home/$username/.autodl/autodl.cfg<<ADC
[options]
gui-server-port = $IRSSI_PORT
gui-server-password = $IRSSI_PASS
allowed = watchdir
ADC
chown -R $username.$username /home/$username/.irssi/
chown -R $username.$username /home/$username
echo $OK
#cp /etc/passwd ${chroot}/etc
#cp /etc/group ${chroot}/etc
cat >>/etc/rssh.conf<<EOF
user=$username:011:00011:/usr/local/chroot
EOF
sudo -u $username /usr/bin/screen -fa -d -m -s torrent /home/$username/cron >/dev/null 2>&1
tmpfile="/tmp/cron"
touch $tmpfile
chmod 777 $tmpfile
sudo -u $username crontab -r>/dev/null 2>&1
echo "@reboot /usr/bin/screen -fa -d -m -S rtorrent /home/$username/cron">>$tmpfile
echo "*/1 * * * * /home/$username/irssi.cron">>$tmpfile
sudo -u $username crontab $tmpfile
rm -rf $tmpfile
