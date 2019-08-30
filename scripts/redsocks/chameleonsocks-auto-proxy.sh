#!/bin/bash
## igordc, 20190622, 20190719, 20190830
## run as root
## ran fine on 16.04.6, 18.04.2
## TODO use containerd

#sudo su -
cd

# edit:
HTTP_PROXY=http://server.localhost:port
HTTPS_PROXY=http://server.localhost:port
SOCKS_PROXY=server.localhost
SOCKS_PORT=1080

# temporary proxy settings
export HTTP_PROXY
export HTTPS_PROXY
export http_proxy=$HTTP_PROXY
export https_proxy=$HTTPS_PROXY

cat > /etc/apt/apt.conf.d/00proxy << EOF
Acquire::http::Proxy "$HTTP_PROXY";
Acquire::https::Proxy "$HTTPS_PROXY";
EOF

# and install docker-ce manually, with the following steps
apt-get remove docker docker-engine docker.io containerd runc -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
apt-get install docker-ce docker-ce-cli containerd.io build-essential -y

wget https://raw.githubusercontent.com/igordcard/chameleonsocks/master/chameleonsocks.sh
wget https://raw.githubusercontent.com/igordcard/chameleonsocks/master/confs/chameleonsocks.exceptions
sed -i "s/PROXY:=my.proxy.com/PROXY:=$SOCKS_PROXY/" chameleonsocks.sh
sed -i "s/PORT:=1080/PORT:=$SOCKS_PORT/" chameleonsocks.sh
sed -i "s/EXCEPTIONS:=\/path\/to\/exceptions\/file/EXCEPTIONS:=chameleonsocks.exceptions/" chameleonsocks.sh

chmod +x chameleonsocks.sh
./chameleonsocks.sh --install

iptables -t nat -A PREROUTING -i cni0 -p tcp -j CHAMELEONSOCKS
iptables -t nat -A PREROUTING -i virbr0 -p tcp -j CHAMELEONSOCKS
iptables -t nat -A PREROUTING -i lxcbr0 -p tcp -j CHAMELEONSOCKS

cat > /etc/apt/apt.conf.d/00proxy << EOF
Acquire::http::Proxy "";
Acquire::https::Proxy "";
EOF

unset HTTP_PROXY
unset HTTPS_PROXY
unset http_proxy
unset https_proxy
