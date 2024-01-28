#!/bin/bash
#Script Variables


#DATABASE HOST
HOST='185.61.137.174'
USER='dragonzx_thunderbolt'
PASS='BoltThunder@@'
DBNAME='dragonzx_thunder'

#PORT OPENVPN
PORT_TCP='1194';
PORT_UDP='53';

timedatectl set-timezone Asia/Manila
server_ip=$(curl -s https://api.ipify.org)
server_interface=$(ip route get 8.8.8.8 | awk '/dev/ {f=NR} f&&NR-1==f' RS=" ")

install_require () {

export DEBIAN_FRONTEND=noninteractive
apt update
apt install -y curl wget cron
apt install -y iptables
apt install -y openvpn netcat httpie php neofetch vnstat
apt install -y screen squid stunnel4 dropbear gnutls-bin python2
apt install -y dos2unix nano unzip jq virt-what net-tools default-mysql-client
apt install -y mlocate dh-make libaudit-dev build-essential fail2ban
#clear
#}&>/dev/null
clear
}

install_squid(){
clear
echo 'Installing proxy.'
{
    apt install -y gcc-4.9 g++-4.9
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 10
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 10
    update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 30
    update-alternatives --set cc /usr/bin/gcc
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 30
    update-alternatives --set c++ /usr/bin/g++
    cd /usr/src
    wget https://raw.githubusercontent.com/nontikweed/tite/main/squid-3.1.23.tar.gz
    tar zxvf squid-3.1.23.tar.gz
    cd squid-3.1.23
    ./configure --prefix=/usr \
      --localstatedir=/var/squid \
      --libexecdir=/usr/lib/squid \
      --srcdir=. \
      --datadir=/usr/share/squid \
      --sysconfdir=/etc/squid \
      --with-default-user=proxy \
      --with-logdir=/var/log/squid \
      --with-pidfile=/var/run/squid.pid
    make -j$(nproc)
    make install
    wget --no-check-certificate -O /etc/init.d/squid https://raw.githubusercontent.com/nontikweed/tite/main/squid.sh
    chmod +x /etc/init.d/squid
    update-rc.d squid defaults
    chown -cR proxy /var/log/squid
    squid -z
    cd /etc/squid/
    rm squid.conf
    echo "acl Argie dst `curl -s https://api.ipify.org`" >> squid.conf
    echo 'http_port 8080
http_port 8181
visible_hostname Proxy
acl PURGE method PURGE
acl HEAD method HEAD
acl POST method POST
acl GET method GET
acl CONNECT method CONNECT
http_access allow Argie
http_reply_access allow all
http_access deny all
icp_access allow all
always_direct allow all
visible_hostname Argie-Proxy
error_directory /usr/share/squid/errors/English' >> squid.conf
    cd /usr/share/squid/errors/English
    rm ERR_INVALID_URL
    echo '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>SECURE PROXY</title><meta name="viewport" content="width=device-width, initial-scale=1"><meta http-equiv="X-UA-Compatible" content="IE=edge"/><link rel="stylesheet" href="https://bootswatch.com/4/slate/bootstrap.min.css" media="screen"><link href="https://fonts.googleapis.com/css?family=Press+Start+2P" rel="stylesheet"><style>body{font-family: "Press Start 2P", cursive;}.fn-color{color: #ffff; background-image: -webkit-linear-gradient(92deg, #f35626, #feab3a); -webkit-background-clip: text; -webkit-text-fill-color: transparent; -webkit-animation: hue 5s infinite linear;}@-webkit-keyframes hue{from{-webkit-filter: hue-rotate(0deg);}to{-webkit-filter: hue-rotate(-360deg);}}</style></head><body><div class="container" style="padding-top: 50px"><div class="jumbotron"><h1 class="display-3 text-center fn-color">SECURE PROXY</h1><h4 class="text-center text-danger">SERVER</h4><p class="text-center">😍 %w 😍</p></div></div></body></html>' >> ERR_INVALID_URL
    chmod 755 *
    /etc/init.d/squid start
cd /etc || exit
wget 'https://raw.githubusercontent.com/nontikweed/tite/main/socks.py' -O /etc/socks.py
dos2unix /etc/socks.py
chmod +x /etc/socks.py
 }&>/dev/null
}

install_openvpn()
{
clear
echo "Installing openvpn."
{
mkdir -p /etc/openvpn/easy-rsa/keys
mkdir -p /etc/openvpn/login
mkdir -p /etc/openvpn/server
mkdir -p /var/www/html/stat
touch /etc/openvpn/server.conf
touch /etc/openvpn/server2.conf

echo 'DNS=1.1.1.1
DNSStubListener=no' >> /etc/systemd/resolved.conf

echo 'dev tun
port PORT_UDP
proto udp
server 10.10.0.0 255.255.0.0
ca /etc/openvpn/easy-rsa/keys/ca.crt
cert /etc/openvpn/easy-rsa/keys/server.crt
key /etc/openvpn/easy-rsa/keys/server.key
dh /etc/openvpn/easy-rsa/keys/dh.pem
ncp-disable
tls-server
tls-version-min 1.2
tls-cipher TLS-ECDHE-RSA-WITH-AES-128-GCM-SHA256
cipher none
auth none
persist-key
persist-tun
ping-timer-rem
compress lz4-v2
keepalive 10 120
reneg-sec 86400
user nobody
group nogroup
client-to-client
duplicate-cn
username-as-common-name
verify-client-cert none
script-security 3
auth-user-pass-verify "/etc/openvpn/login/auth_vpn" via-env #
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
push "compress lz4-v2"
push "persist-key"
push "persist-tun"
client-connect /etc/openvpn/login/connect.sh
client-disconnect /etc/openvpn/login/disconnect.sh
log /etc/openvpn/server/udpserver.log
status /etc/openvpn/server/udpclient.log
status-version 2
verb 3' > /etc/openvpn/server.conf

sed -i "s|PORT_UDP|$PORT_UDP|g" /etc/openvpn/server.conf

echo 'dev tun
port PORT_TCP
proto tcp
server 10.20.0.0 255.255.0.0
ca /etc/openvpn/easy-rsa/keys/ca.crt
cert /etc/openvpn/easy-rsa/keys/server.crt
key /etc/openvpn/easy-rsa/keys/server.key
dh /etc/openvpn/easy-rsa/keys/dh.pem
ncp-disable
tls-server
tls-version-min 1.2
tls-cipher TLS-ECDHE-RSA-WITH-AES-128-GCM-SHA256
cipher none
auth none
persist-key
persist-tun
ping-timer-rem
compress lz4-v2
keepalive 10 120
reneg-sec 86400
user nobody
group nogroup
client-to-client
duplicate-cn
username-as-common-name
verify-client-cert none
script-security 3
auth-user-pass-verify "/etc/openvpn/login/auth_vpn" via-env #
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
push "compress lz4-v2"
push "persist-key"
push "persist-tun"
client-connect /etc/openvpn/login/connect.sh
client-disconnect /etc/openvpn/login/disconnect.sh
log /etc/openvpn/server/tcpserver.log
status /etc/openvpn/server/tcpclient.log
status-version 2
verb 3' > /etc/openvpn/server2.conf

sed -i "s|PORT_TCP|$PORT_TCP|g" /etc/openvpn/server2.conf

cat <<\EOM >/etc/openvpn/login/config.sh
#!/bin/bash
HOST='DBHOST'
USER='DBUSER'
PASS='DBPASS'
DB='DBNAME'
EOM

sed -i "s|DBHOST|$HOST|g" /etc/openvpn/login/config.sh
sed -i "s|DBUSER|$USER|g" /etc/openvpn/login/config.sh
sed -i "s|DBPASS|$PASS|g" /etc/openvpn/login/config.sh
sed -i "s|DBNAME|$DBNAME|g" /etc/openvpn/login/config.sh

wget -O /etc/openvpn/login/auth_vpn "https://raw.githubusercontent.com/nontikweed/tite/main/premium.sh"

#client-connect file
wget -O /etc/openvpn/login/connect.sh "https://raw.githubusercontent.com/nontikweed/tite/main/connect"

sed -i "s|SERVER_IP|$server_ip|g" /etc/openvpn/login/connect.sh

#TCP client-disconnect file
wget -O /etc/openvpn/login/disconnect.sh "https://raw.githubusercontent.com/nontikweed/tite/main/disconnect.sh"

sed -i "s|SERVER_IP|$server_ip|g" /etc/openvpn/login/disconnect.sh


cat << EOF > /etc/openvpn/easy-rsa/keys/ca.crt
-----BEGIN CERTIFICATE-----
MIIDSDCCAjCgAwIBAgIUXKh6tJLj3JobFaM6r18ylFWsGRswDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAwwKbm9udGlrd2VlZDAeFw0yMzEyMTMwODM4MzFaFw0zMzEy
MTAwODM4MzFaMBUxEzARBgNVBAMMCm5vbnRpa3dlZWQwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQCuaWqJaxsrb77AKu9/yUbERQ83yAG7dp3ZGKl/B3k0
lrS66nDvFLt7h2F9ST1RRm50B1YJsHjrl/f+taI6sapIyoZnLu0WrXaJld8Rgf0h
OA6oNEix1Godah/KsVfDpGbiTBjpUin+/qf6xBAjKjNeP7jqdIfEdtFjSS9X4Ymz
W23Nv0XyPsWKy5uefIxnXjUDkKiRxveSazdnOKLsLixsR/9FQvfr3u3DO9Xujudv
5l96Ccae2XwusiE7decjGboqaA6ci45IU9eZiSK8tD+BIBQEWLrbDMIzdirEAvgn
Sl/vUHUw/tdA0Du5GYHYNfPVNkGI4N3HSgRjWDTEgmR7AgMBAAGjgY8wgYwwHQYD
VR0OBBYEFBk6fQhlvyX3waYYaqNk14mHP86vMFAGA1UdIwRJMEeAFBk6fQhlvyX3
waYYaqNk14mHP86voRmkFzAVMRMwEQYDVQQDDApub250aWt3ZWVkghRcqHq0kuPc
mhsVozqvXzKUVawZGzAMBgNVHRMEBTADAQH/MAsGA1UdDwQEAwIBBjANBgkqhkiG
9w0BAQsFAAOCAQEAMFIiy0BEKieAVya05b8kWleoKX4WxehX2/2TSvqQaFPch2Qj
gsU2Xaee90lMxkLvciY2zjq1RMmzdd3p/t9HvnoyBMbcU2R1SEjWAoo5T3nEEkXo
n8/Rgqhxy1N8OYMd4VaqwclzwTzN2lZ2CHzxHrIk1ivg3f9pv0eRFJ6QfTrIpQ0M
KfkFbMuwnH9BQJSb93spLiU2nY+xgU4dEe6VgFjYDbOcyRN7E5uE/2ottieMLkDZ
PHxw8CG5fM+iSIm29HmnEdi7oxEf17gcM1HegUY89G9V15EE/kJNOXBF/63rMRSl
86Qd/8HD6QztaOCDf1EuyJ8DdVlQQmeEtftdbg==
-----END CERTIFICATE-----
EOF

cat << EOF > /etc/openvpn/easy-rsa/keys/server.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            b4:0b:fe:7c:30:e5:9b:3a:a4:5f:c7:d9:a2:61:45:94
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=nontikweed
        Validity
            Not Before: Dec 13 08:38:55 2023 GMT
            Not After : Nov 27 08:38:55 2026 GMT
        Subject: CN=nontikweed
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:a3:85:82:57:d8:b2:d7:4c:17:bd:f4:56:f6:4d:
                    a3:1c:a2:cc:78:64:8a:d2:94:9a:48:50:75:2a:c7:
                    05:ff:36:e2:a3:48:6d:41:1d:c1:79:e4:78:f2:cb:
                    4d:e0:8f:b3:ed:6b:25:3d:00:1a:05:c9:e5:e5:7a:
                    0d:5b:7f:b4:28:f4:49:20:21:3a:b0:b9:b4:e2:6d:
                    bd:d0:c6:94:ff:6f:8f:04:51:9b:45:fd:c8:46:ca:
                    7c:55:af:89:2e:13:50:5a:47:e2:9a:5f:a1:d0:8f:
                    9a:2d:b0:c7:5c:a7:4a:74:64:64:22:20:9e:2d:b8:
                    61:18:35:b5:e9:3b:a8:77:b5:0a:09:de:e0:e1:10:
                    5b:1d:e0:bf:74:d6:73:3b:7a:e7:a9:6f:f2:74:91:
                    b3:6f:42:14:59:4f:63:ec:b3:59:01:11:82:1c:57:
                    fc:c9:52:c8:e8:f3:ab:c7:77:a4:fc:ad:f8:5b:44:
                    eb:fa:29:56:ea:2e:c6:c8:e9:79:ac:51:42:9f:c5:
                    dd:b5:d8:f0:cf:91:e3:6f:3f:5f:92:7d:6a:f4:3a:
                    1c:3b:7a:6f:a3:5c:e7:0d:f1:64:0d:27:77:7e:23:
                    c0:3f:12:1d:cd:c0:1e:b1:18:a3:e9:d8:fc:34:fc:
                    38:f4:17:78:e6:69:e8:a4:0d:48:a8:31:df:7a:86:
                    c1:9f
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            X509v3 Subject Key Identifier: 
                21:D3:88:DE:9C:B0:8D:C8:07:4F:C4:50:54:E1:4A:7D:CF:62:5B:8F
            X509v3 Authority Key Identifier: 
                keyid:19:3A:7D:08:65:BF:25:F7:C1:A6:18:6A:A3:64:D7:89:87:3F:CE:AF
                DirName:/CN=nontikweed
                serial:5C:A8:7A:B4:92:E3:DC:9A:1B:15:A3:3A:AF:5F:32:94:55:AC:19:1B

            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
            X509v3 Key Usage: 
                Digital Signature, Key Encipherment
            X509v3 Subject Alternative Name: 
                DNS:nontikweed
    Signature Algorithm: sha256WithRSAEncryption
         73:99:9c:8d:76:2a:08:dd:01:d5:ca:34:6a:24:f2:0c:f4:9e:
         4c:68:69:90:28:7e:49:b2:e2:4b:ef:c3:e4:2a:0e:65:44:ea:
         0b:4a:04:87:61:c7:4a:a5:ea:a1:ab:0d:d8:3c:b4:af:26:9c:
         c2:d7:15:66:cd:6e:f3:fb:01:be:f1:18:1d:69:47:31:67:fe:
         ab:50:f7:9a:7d:d4:0e:68:77:83:84:41:ac:66:f4:79:ba:fd:
         62:c2:a4:55:a4:5b:17:53:0e:e9:e8:b1:2f:91:dd:d7:12:be:
         a1:7e:ea:13:13:58:53:3d:04:75:14:2d:6a:f5:8b:e7:b1:b9:
         19:e3:06:7f:ae:61:e0:d5:8b:38:a7:a6:07:e3:38:97:18:2e:
         42:80:e8:ed:7d:4c:9c:69:a3:75:b2:fb:a3:c8:aa:8c:9f:64:
         7e:88:90:81:c4:a9:b8:27:b1:d1:16:b7:e5:84:c2:56:9e:71:
         83:9b:78:0b:65:78:04:78:30:50:48:6f:e8:b9:30:1a:ce:95:
         47:24:1c:82:3b:7d:c7:11:d7:b0:d8:0f:2e:45:eb:e0:4e:bc:
         30:89:e0:0f:62:30:4d:a7:e5:83:f2:63:ca:e0:e8:a8:58:4f:
         cd:e1:b5:05:00:f6:e4:b6:1c:c2:3d:bd:b7:2f:08:da:49:61:
         07:dc:d9:38
-----BEGIN CERTIFICATE-----
MIIDbjCCAlagAwIBAgIRALQL/nww5Zs6pF/H2aJhRZQwDQYJKoZIhvcNAQELBQAw
FTETMBEGA1UEAwwKbm9udGlrd2VlZDAeFw0yMzEyMTMwODM4NTVaFw0yNjExMjcw
ODM4NTVaMBUxEzARBgNVBAMMCm5vbnRpa3dlZWQwggEiMA0GCSqGSIb3DQEBAQUA
A4IBDwAwggEKAoIBAQCjhYJX2LLXTBe99Fb2TaMcosx4ZIrSlJpIUHUqxwX/NuKj
SG1BHcF55Hjyy03gj7PtayU9ABoFyeXleg1bf7Qo9EkgITqwubTibb3QxpT/b48E
UZtF/chGynxVr4kuE1BaR+KaX6HQj5otsMdcp0p0ZGQiIJ4tuGEYNbXpO6h3tQoJ
3uDhEFsd4L901nM7euepb/J0kbNvQhRZT2Pss1kBEYIcV/zJUsjo86vHd6T8rfhb
ROv6KVbqLsbI6XmsUUKfxd212PDPkeNvP1+SfWr0Ohw7em+jXOcN8WQNJ3d+I8A/
Eh3NwB6xGKPp2Pw0/Dj0F3jmaeikDUioMd96hsGfAgMBAAGjgbgwgbUwCQYDVR0T
BAIwADAdBgNVHQ4EFgQUIdOI3pywjcgHT8RQVOFKfc9iW48wUAYDVR0jBEkwR4AU
GTp9CGW/JffBphhqo2TXiYc/zq+hGaQXMBUxEzARBgNVBAMMCm5vbnRpa3dlZWSC
FFyoerSS49yaGxWjOq9fMpRVrBkbMBMGA1UdJQQMMAoGCCsGAQUFBwMBMAsGA1Ud
DwQEAwIFoDAVBgNVHREEDjAMggpub250aWt3ZWVkMA0GCSqGSIb3DQEBCwUAA4IB
AQBzmZyNdioI3QHVyjRqJPIM9J5MaGmQKH5JsuJL78PkKg5lROoLSgSHYcdKpeqh
qw3YPLSvJpzC1xVmzW7z+wG+8RgdaUcxZ/6rUPeafdQOaHeDhEGsZvR5uv1iwqRV
pFsXUw7p6LEvkd3XEr6hfuoTE1hTPQR1FC1q9YvnsbkZ4wZ/rmHg1Ys4p6YH4ziX
GC5CgOjtfUycaaN1svujyKqMn2R+iJCBxKm4J7HRFrflhMJWnnGDm3gLZXgEeDBQ
SG/ouTAazpVHJByCO33HEdew2A8uRevgTrwwieAPYjBNp+WD8mPK4OioWE/N4bUF
APbkthzCPb23LwjaSWEH3Nk4
-----END CERTIFICATE-----
EOF

cat << EOF > /etc/openvpn/easy-rsa/keys/server.key
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCjhYJX2LLXTBe9
9Fb2TaMcosx4ZIrSlJpIUHUqxwX/NuKjSG1BHcF55Hjyy03gj7PtayU9ABoFyeXl
eg1bf7Qo9EkgITqwubTibb3QxpT/b48EUZtF/chGynxVr4kuE1BaR+KaX6HQj5ot
sMdcp0p0ZGQiIJ4tuGEYNbXpO6h3tQoJ3uDhEFsd4L901nM7euepb/J0kbNvQhRZ
T2Pss1kBEYIcV/zJUsjo86vHd6T8rfhbROv6KVbqLsbI6XmsUUKfxd212PDPkeNv
P1+SfWr0Ohw7em+jXOcN8WQNJ3d+I8A/Eh3NwB6xGKPp2Pw0/Dj0F3jmaeikDUio
Md96hsGfAgMBAAECggEACDgHqx6rLoMWlmeXj12rmx7bpBl5mMf7UTMqEHJcbM13
armTNDioptXC9oEdcvIGGyLNhllg9XWGZphR3411orFUk5bX+lX7L35QkhPJHWWg
DJmFcmklDdnTkgL2pCg4W7FNRHEWEwOEvlMqUg/egCcjmUuGZ8nip3Lbp9Nlzk5o
kKJvk6pXOlaQ9nKTZZmguaz1aDbBl5rF94Dx360KQgEN2+C45KLuk96sdCgiEOYg
WwXy3yZoUvtLOJZ86hIXDQXql+dViYDjjiwGjtMguFoK34Omr75r1A5KN5psgMJm
so1CgyLyBT1x6vt1sJH1Ob78ij8UfOD9UMN1wO7xsQKBgQDXTpNpJBnT/jJfOx8n
CKdnawHlJRQXZ1i6dOOTZS8lRptbzHslm3otnHHTcPQFnfEkrX55WMEj1w0qN6yZ
N1KfHG7APaSxEVj3EkuP0KOcyhLVL9CIHuNVk6nDZkb4oN9d7sPRsrHrCSYKeNKS
7Q/Lf+KxwDHLnHCPNYiaJ8hclQKBgQDCbVgyaBo1UAmDvbcngJ54/hrPgxUEdGBK
o2D7iU+D2eml2dfOhk0+SXTrPILT+2Z2o83C55BXpjOgTpRE+r7S1X1huBfZF2iP
LPSv+4qRvcGvEMCVB2t0/wLnicLMpRXLx4bys0SDiOcB3Cri0/9APuAzFId7sTtA
ihJN124kYwKBgH8ez34WaIF35fnACGadf2laDqZiO/iNdh+wf+U4qptRksyicFsF
7x8a7UGvwQPH+uZy4Od4daBZilZQxME5nrh+qw0p2CELYwGNdbuVreQWkwP31SFp
S0PtiR/rNR/6q6bkIA2hedaRcjpgl8NT4C2AdjIIjd3voa2MJ/kMYAn5AoGAW2Es
/LP07W2qqyJ1fLl0wgUb8L/5FtjjkPDs2gwVNTEsIWkbhtOUZlv7+bu8+YjFBanD
QYG4U5mn1gZYpXr8SPdSMKVnf/8Cg5hrgHLHE+yNpYxIF0MffCOG5+/VgH1umxIy
GMusve2QNU2XUni1FSr4EMnrS3VnFdRO+grwl2UCgYBg8zUOBeqYrAvM/6QRYuKs
0doZj3MYvV+6mQbgdfCBcnmhl/TSlCxw0T8uUpAe4qEbkF4+q8d5qfV8x8VsFaat
EiwKG+74Jbm+7BZlf7srtZLrkq+ypHHNpVMcUTKOyvWF10evXQ+KrZt4mlhzrBxI
V3GMjpctESgBNqoxDWpH0w==
-----END PRIVATE KEY-----
EOF

cat << EOF > /etc/openvpn/easy-rsa/keys/dh.pem
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEAhib7LHZ4gotyERBsW33c0QpZ3cH/DU4vhzPZHPWyDA+auoSmEQxw
if0Py+qM3PU/MM8Vid9TbUJJ09qOPan6hy36d9yMfp/NDrnwofpu/hSgxu+sVx+j
1VPO2KqAsbCfslpYV6JYaZxa9oLMA7vweCv+XyFphAnHoGoRGodKHLxOyymkRIAb
6KzZJyfqGj2Foy36EHp2t+w8aQZN8l3m29Zx19H/sPCURDKrF7ii3DHR8F6b8vGB
rEzoyg1qv+Hl9Jm/oneZ4FZKxcXhRy7cpQWsve01iboBAsrcVx1OI4KQlbpcEtzf
n/406HSgtsB8yWPDNga/N7OONk8aTJtbWwIBAg==
-----END DH PARAMETERS-----
EOF

dos2unix /etc/openvpn/login/auth_vpn
dos2unix /etc/openvpn/login/connect.sh
dos2unix /etc/openvpn/login/disconnect.sh

chmod 777 -R /etc/openvpn/
chmod 755 /etc/openvpn/server.conf
chmod 755 /etc/openvpn/server2.conf
chmod 755 /etc/openvpn/login/connect.sh
chmod 755 /etc/openvpn/login/disconnect.sh
chmod 755 /etc/openvpn/login/config.sh
chmod 755 /etc/openvpn/login/auth_vpn
}&>/dev/null
}


install_firewall_kvm () {
clear
#echo "Installing iptables."

echo "net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.eth0.rp_filter=0
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

sysctl -p

iptables -F
iptables -t nat -A PREROUTING -p udp --dport 20000:50000 -j DNAT --to-destination :5666
iptables -t nat -A POSTROUTING -s 10.20.0.0/22 -o "$server_interface" -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.20.0.0/22 -o "$server_interface" -j SNAT --to-source "$server_ip"
iptables -t nat -A POSTROUTING -s 10.30.0.0/22 -o "$server_interface" -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.30.0.0/22 -o "$server_interface" -j SNAT --to-source "$server_ip"
iptables -t filter -A INPUT -p udp -m udp --dport 20100:20900 -m state --state NEW -m recent --update --seconds 30 --hitcount 10 --name DEFAULT --mask 255.255.255.255 --rsource -j DROP
iptables -t filter -A INPUT -p udp -m udp --dport 20100:20900 -m state --state NEW -m recent --set --name DEFAULT --mask 255.255.255.255 --rsource
iptables-save > /etc/iptables_rules.v4
ip6tables-save > /etc/iptables_rules.v6
#}&>/dev/null
}

install_stunnel() {
  {
cd /etc/stunnel/ || exit

echo "-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQClmgCdm7RB2VWK
wfH8HO/T9bxEddWDsB3fJKpM/tiVMt4s/WMdGJtFdRlxzUb03u+HT6t00sLlZ78g
ngjxLpJGFpHAGdVf9vACBtrxv5qcrG5gd8k7MJ+FtMTcjeQm8kVRyIW7cOWxlpGY
6jringYZ6NcRTrh/OlxIHKdsLI9ddcekbYGyZVTm1wd22HVG+07PH/AeyY78O2+Z
tbjxGTFRSYt3jUaFeUmWNtxqWnR4MPmC+6iKvUKisV27P89g8v8CiZynAAWRJ0+A
qp+PWxwHi/iJ501WdLspeo8VkXIb3PivyIKC356m+yuuibD2uqwLZ2//afup84Qu
pRtgW/PbAgMBAAECggEAVo/efIQUQEtrlIF2jRNPJZuQ0rRJbHGV27tdrauU6MBT
NG8q7N2c5DymlT75NSyHRlKVzBYTPDjzxgf1oqR2X16Sxzh5uZTpthWBQtal6fmU
JKbYsDDlYc2xDZy5wsXnCC3qAaWs2xxadPUS3Lw/cjGsoeZlOFP4QtV/imLseaws
7r4KZE7SVO8dF8Xtcy304Bd7UsKClnbCrGsABUF/rqA8g34o7yrpo9XqcwbF5ihQ
TbnB0Ns8Bz30pjgGjJZTdTL3eskP9qMJWo/JM76kSaJWReoXTws4DlQHxO29z3eK
zKdxieXaBGMwFnv23JvXKJ5eAnxzqsL6a+SuNPPN4QKBgQDQhisSDdjUJWy0DLnJ
/HjtsnQyfl0efOqAlUEir8r5IdzDTtAEcW6GwPj1rIOm79ZeyysT1pGN6eulzS1i
6lz6/c5uHA9Z+7LT48ZaQjmKF06ItdfHI9ytoXaaQPMqW7NnyOFxCcTHBabmwQ+E
QZDFkM6vVXL37Sz4JyxuIwCNMQKBgQDLThgKi+L3ps7y1dWayj+Z0tutK2JGDww7
6Ze6lD5gmRAURd0crIF8IEQMpvKlxQwkhqR4vEsdkiFFJQAaD+qZ9XQOkWSGXvKP
A/yzk0Xu3qL29ZqX+3CYVjkDbtVOLQC9TBG60IFZW79K/Zp6PhHkO8w6l+CBR+yR
X4+8x1ReywKBgQCfSg52wSski94pABugh4OdGBgZRlw94PCF/v390En92/c3Hupa
qofi2mCT0w/Sox2f1hV3Fw6jWNDRHBYSnLMgbGeXx0mW1GX75OBtrG8l5L3yQu6t
SeDWpiPim8DlV52Jp3NHlU3DNrcTSOFgh3Fe6kpot56Wc5BJlCsliwlt0QKBgEol
u0LtbePgpI2QS41ewf96FcB8mCTxDAc11K6prm5QpLqgGFqC197LbcYnhUvMJ/eS
W53lHog0aYnsSrM2pttr194QTNds/Y4HaDyeM91AubLUNIPFonUMzVJhM86FP0XK
3pSBwwsyGPxirdpzlNbmsD+WcLz13GPQtH2nPTAtAoGAVloDEEjfj5gnZzEWTK5k
4oYWGlwySfcfbt8EnkY+B77UVeZxWnxpVC9PhsPNI1MTNET+CRqxNZzxWo3jVuz1
HtKSizJpaYQ6iarP4EvUdFxHBzjHX6WLahTgUq90YNaxQbXz51ARpid8sFbz1f37
jgjgxgxbitApzno0E2Pq/Kg=
-----END PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
MIIDRTCCAi2gAwIBAgIUOvs3vdjcBtCLww52CggSlAKafDkwDQYJKoZIhvcNAQEL
BQAwMjEQMA4GA1UEAwwHS29ielZQTjERMA8GA1UECgwIS29iZUtvYnoxCzAJBgNV
BAYTAlBIMB4XDTIxMDcwNzA1MzQwN1oXDTMxMDcwNTA1MzQwN1owMjEQMA4GA1UE
AwwHS29ielZQTjERMA8GA1UECgwIS29iZUtvYnoxCzAJBgNVBAYTAlBIMIIBIjAN
BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZoAnZu0QdlVisHx/Bzv0/W8RHXV
g7Ad3ySqTP7YlTLeLP1jHRibRXUZcc1G9N7vh0+rdNLC5We/IJ4I8S6SRhaRwBnV
X/bwAgba8b+anKxuYHfJOzCfhbTE3I3kJvJFUciFu3DlsZaRmOo64p4GGejXEU64
fzpcSBynbCyPXXXHpG2BsmVU5tcHdth1RvtOzx/wHsmO/DtvmbW48RkxUUmLd41G
hXlJljbcalp0eDD5gvuoir1CorFduz/PYPL/AomcpwAFkSdPgKqfj1scB4v4iedN
VnS7KXqPFZFyG9z4r8iCgt+epvsrromw9rqsC2dv/2n7qfOELqUbYFvz2wIDAQAB
o1MwUTAdBgNVHQ4EFgQUcKFL6tckon2uS3xGrpe1Zpa68VEwHwYDVR0jBBgwFoAU
cKFL6tckon2uS3xGrpe1Zpa68VEwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0B
AQsFAAOCAQEAYQP0S67eoJWpAMavayS7NjK+6KMJtlmL8eot/3RKPLleOjEuCdLY
QvrP0Tl3M5gGt+I6WO7r+HKT2PuCN8BshIob8OGAEkuQ/YKEg9QyvmSm2XbPVBaG
RRFjvxFyeL4gtDlqb9hea62tep7+gCkeiccyp8+lmnS32rRtFa7PovmK5pUjkDOr
dpvCQlKoCRjZ/+OfUaanzYQSDrxdTSN8RtJhCZtd45QbxEXzHTEaICXLuXL6cmv7
tMuhgUoefS17gv1jqj/C9+6ogMVa+U7QqOvL5A7hbevHdF/k/TMn+qx4UdhrbL5Q
enL3UGT+BhRAPiA1I5CcG29RqjCzQoaCNg==
-----END CERTIFICATE-----" >> stunnel.pem

echo "debug = 0
output = /tmp/stunnel.log
cert = /etc/stunnel/stunnel.pem
[openvpn-tcp]
connect = PORT_TCP  
accept = 443 
[openvpn-udp]
connect = PORT_UDP
accept = 444
" >> stunnel.conf

sed -i "s|PORT_TCP|$PORT_TCP|g" /etc/stunnel/stunnel.conf
sed -i "s|PORT_UDP|$PORT_UDP|g" /etc/stunnel/stunnel.conf
cd /etc/default && rm stunnel4

echo 'ENABLED=1
FILES="/etc/stunnel/*.conf"
OPTIONS=""
PPP_RESTART=0
RLIMITS=""' >> stunnel4 

chmod 755 stunnel4
sudo service stunnel4 restart
  } &>/dev/null
}

install_hysteria(){
clear
echo 'Installing hysteria.'
{
        wget -N --no-check-certificate -q -O ~/install_server.sh https://raw.githubusercontent.com/nontikweed/blaire69/master/install_server.sh > /dev/null 2>&1
        chmod +x ~/install_server.sh > /dev/null 2>&1
        ~/install_server.sh --version v1.3.5 > /dev/null 2>&1

rm -f /etc/hysteria/config.json

echo '{
  "listen": ":5666",
  "cert": "/etc/openvpn/easy-rsa/keys/server.crt",
  "key": "/etc/openvpn/easy-rsa/keys/server.key",
  "up_mbps": 100,
  "down_mbps": 100,
  "disable_udp": false,
  "obfs": "boy",
  "auth": {
    "mode": "external",
    "config": {
    "cmd": "./.auth.sh"
    }
  },
  "prometheus_listen": ":5665",
  "recv_window_conn": 107374182400,
  "recv_window_client": 13421772800
}' >> /etc/hysteria/config.json

cat <<\EOM >/etc/hysteria/config.sh
#!/bin/bash
HOST='185.61.137.174'
USER='dragonzx_thunderbolt'
PASS='BoltThunder@@'
DB='dragonzx_thunder'
EOM

cat <<"EOM" >/etc/hysteria/.auth.sh
#!/bin/bash
. /etc/hysteria/config.sh

if [ $# -ne 4 ]; then
    echo "invalid number of arguments"
    exit 1
fi

ADDR=$1
AUTH=$2
SEND=$3
RECV=$4

USERNAME=$(echo "$AUTH" | cut -d ":" -f 1)
PASSWORD=$(echo "$AUTH" | cut -d ":" -f 2)

USERNAME=$(echo "$AUTH" | cut -d ":" -f 1)
PASSWORD=$(echo "$AUTH" | cut -d ":" -f 2)


Query="SELECT user_name FROM users WHERE user_name='$USERNAME' AND auth_vpn=md5('$PASSWORD') AND status='live' AND is_freeze=0 AND is_ban=0 AND (duration > 0 OR vip_duration > 0 OR private_duration > 0)"
user_name=`mysql -u $USER -p$PASS -D $DB -h $HOST -sN -e "$Query"`
[ "$user_name" != '' ] && [ "$user_name" = "$USERNAME" ] && echo "user : $username" && echo 'authentication ok.' && exit 0 || echo 'authentication failed.'; exit 1
EOM

sysctl -w net.core.rmem_max=16777216
sysctl -w net.core.wmem_max=16777216

chmod 755 /etc/hysteria/config.json
chmod 755 /etc/hysteria/hysteria.crt
chmod 755 /etc/hysteria/hysteria.key
chmod 755 /etc/hysteria/.auth.sh

systemctl enable hysteria-server.service
systemctl restart hysteria-server.service

wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/nontikweed/tite/main/badvpn-udpgw64"
chmod +x /usr/bin/badvpn-udpgw
ps x | grep 'udpvpn' | grep -v 'grep' || screen -dmS udpvpn /usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 10000 --max-connections-for-client 10 --client-socket-sndbuf 10000
} &>/dev/null
}

install_rclocal(){
  {
  sed -i 's/Listen 80/Listen 81/g' /etc/apache2/ports.conf
    systemctl restart apache2
    
    sudo systemctl restart stunnel4
    sudo systemctl enable openvpn@server.service
    sudo systemctl start openvpn@server.service
    sudo systemctl enable openvpn@server2.service
    sudo systemctl start openvpn@server2.service    
    
    echo "[Unit]
Description=NetHub
Documentation=http://nethubvpn.net

[Service]
Type=oneshot
ExecStart=/bin/bash /etc/rc.local
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/argie.service
    echo '#!/bin/sh -e
service ufw stop
iptables-restore < /etc/iptables_rules.v4
ip6tables-restore < /etc/iptables_rules.v6
sysctl -p
service stunnel4 restart
systemctl restart openvpn@server.service
systemctl restart openvpn@server2.service
screen -dmS socks python /etc/socks.py 80
ps x | grep 'udpvpn' | grep -v 'grep' || screen -dmS udpvpn /usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 10000 --max-connections-for-client 10 --client-socket-sndbuf 10000
screen -dmS webinfo php -S 0.0.0.0:5623 -t /root/.web/
bash /etc/hysteria/monitor.sh openvpn
bash /etc/hysteria/online.sh
exit 0' >> /etc/rc.local
    sudo chmod +x /etc/rc.local
    systemctl daemon-reload
    sudo systemctl enable argie
    sudo systemctl start argie.service
    
echo "tcp_port=TCP_PORT
udp_port=UDP_PORT
socket_port=80
squid_port=8080
hysteria_port=5666
tcp_ssl_port=1194
udp_ssl_port=442" >> /root/.ports

sed -i "s|TCP_PORT|$PORT_TCP|g" /root/.ports
sed -i "s|UDP_PORT|$PORT_UDP|g" /root/.ports

sed -i "s|SERVERIP|$server_ip|g" /etc/.counter
  }&>/dev/null
}

start_service () {
clear
echo 'Starting..'
{
sudo crontab -l | { echo "* * * * * pgrep -x stunnel4 >/dev/null && echo 'GOOD' || /etc/init.d/stunnel4 restart"; } | crontab -
sudo systemctl restart cron
} &>/dev/null
clear
history -c;
reboot
}

install_require
install_squid
install_openvpn
install_stunnel
install_hysteria
install_firewall_kvm
install_rclocal
start_service
