#!/bin/bash
### igordc,            ###
### 20190823,25,27     ###
### run as root user   ###
#####                #####
### not all lines have ###
#### have been tested ####
#####                #####

# chameleonsocks will be deployed in the external router's
# network namespace, for the case when this namespace directly
# connects to the internet via its gateway interface (no NAT)

# start as root, in a python environment with openstack cli installed
# as well as with keystone credentials launched in the shell session

export SOCKS_PROXY_ADDR=your.proxy.com # edit
export SOCKS_PROXY_PORT=1080           # edit
export SOCKS_PROXY_TYPE=socks5
HTTP_PROXY=http://your.proxy.com:port  # edit
HTTPS_PROXY=http://your.proxy.com:port # edit
ADDITIONAL_PROXY_EXCEPTIONS=""         # edit
#ADDITIONAL_PROXY_EXCEPTIONS="1.0.0.0
#2.0.0.0
#3.0.0.0"
# -> additional proxy exceptions are network ranges
#    to be ignored by chameleonsocks/redsocks
# -> also edit dns stuff below

ROUTER=demo-router # change according to external router's name
ROUTER_ID=$(openstack router show $ROUTER -f yaml | grep -E "^id" | cut -d ":" -f 2 | awk '{$1=$1;print}')
GW_PORT_ID=$(openstack port list -c id -c device_owner --device-id $ROUTER_ID | grep router_gateway | cut -d "|" -f 2 | awk '{$1=$1;print}')
INT_PORT_IDS=($(openstack port list -c id -c device_owner --device-id $ROUTER_ID | grep router_interface | cut -d "|" -f 2 | awk '{$1=$1;print}' | xargs))


# fix DNS for the netns (edit nameserver addresses and search domain):
mkdir -p /etc/netns/qrouter-$ROUTER_ID
cat > /etc/netns/qrouter-$ROUTER_ID/resolv.conf << EOF
nameserver 10.0.0.1
nameserver 10.0.1.1
search your.domain.com
EOF

ip netns exec qrouter-$ROUTER_ID env INT_PORT_IDS=$INT_PORT_IDS bash

# temporarily enable proxy to download chameleonsocks, etc
export http_proxy=$HTTP_PROXY
export https_proxy=$HTTPS_PROXY
git clone https://github.com/igordcard/chameleonsocks.git
apt-get update
apt-get install -y redsocks curl python python-pip iptables
pip install iptools
systemctl stop redsocks
systemctl disable redsocks
unset http_proxy
unset https_proxy

# install chameleonsocks at namespace level:
cd chameleonsocks/confs
cp redsocks.conf /etc/redsocks.conf
cp chameleonsocks.exceptions /etc/
echo "1.2" > /etc/chameleonsocks-version
# apply proxy exceptions:
echo $ADDITIONAL_PROXY_EXCEPTIONS >> /etc/chameleonsocks.exceptions

# start chameleonsocks, TODO service
./chameleonsocks &

# allow traffic from OpenStack internal networks to use chameleonsocks
for intf in "${INT_PORT_IDS[@]}"
do
 iptables -t nat -D PREROUTING -i qr-${intf:0:11} -p tcp -j CHAMELEONSOCKS
 iptables -t nat -A PREROUTING -i qr-${intf:0:11} -p tcp -j CHAMELEONSOCKS
done
