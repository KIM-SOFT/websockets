#!/bin/sh

read -p "Do you wish to install this program? (y / n)? " yn
    if [[ "$yn" =~ 'y' ]]; then continue; fi
    if [[ "$yn" =~ 'n' ]]; then exit; fi

apt update
apt install stunnel4 dropbear python unzip cmake openssl screen wget -y

read -p "Enter SSH Welcome Text: " banner
echo ${banner} | sudo tee -a /etc/dropbear/banner

read -p "Enter Your CDN Domain: " domain

read -p "Enter Your IP Address: " ipss

echo 'NO_START=0
DROPBEAR_PORT=550
DROPBEAR_EXTRA_ARGS=
DROPBEAR_BANNER="/etc/dropbear/banner"
DROPBEAR_RECEIVE_WINDOW=65536' > /etc/default/dropbear
service dropbear restart
echo 'cert = /etc/stunnel/stunnel.pem
client = no
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
TIMEOUTclose = 0

[stunnel]
accept = '${ipss}':443
connect = '${ipss}':80' > /etc/stunnel/1.conf
rm ssh.py
wget https://raw.githubusercontent.com/SunderBusket/xraus/main/ssh.py
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem
service stunnel4 restart
screen -dmS proxy python ssh.py 80 ${ipss}
service dropbear restart
service stunnel4 restart
wget https://github.com/ambrop72/badvpn/archive/refs/tags/1.999.130.zip
unzip 1.999.130.zip
cd badvpn-1.999.130
cmake ~/badvpn-1.999.130 -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
make install
screen -dmS udp badvpn-udpgw --listen-addr 127.0.0.1:7300
cd /root
echo 'screen -dmS proxy python ssh.py 80 '${ipss}' 
screen -dmS udp badvpn-udpgw --listen-addr 127.0.0.1:7300' > execs.sh
chmod +x execs.sh
echo "@reboot root /root/execs.sh" | sudo tee -a /etc/crontab


clear
echo Work is done!
echo CDN WS SSH Installed!
echo Here are the configs
echo Payloads:
echo GET wss://womensaid.org.uk/ HTTP/1.1[crlf]Host: ${domain}[crlf]Connection: keep-alive[crlf]Upgrade: websocket[crlf][crlf]
echo GET / HTTP/1.1[crlf]Host: ${domain}[crlf]Upgrade: websocket[crlf][crlf]
echo SNI - womensaid.org.uk
echo ssh - womensaid.org.uk:443@root:ssh_pass
