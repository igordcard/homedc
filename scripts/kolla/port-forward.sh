#!/bin/bash

$EXT_PORT=$1
$INT_IP=$2
$INT_PORT=$3
# TCP only
ROUTER=demo-router # change according to external router's name
ROUTER_ID=$(openstack router show $ROUTER -f yaml | grep -E "^id" | cut -d ":" -f 2 | awk '{$1=$1;print}')
QG_ID=($(openstack port list -c id -c device_owner --device-id $ROUTER_ID | grep router_gateway | cut -d "|" -f 2 | awk '{$1=$1;print}' | xargs))

sudo ip netns exec qrouter-$ROUTER_ID env QG_ID=$QG_ID bash

iptables -t nat -D PREROUTING -p tcp -i qg-${QG_ID:0:11} --dport $EXT_PORT -j DNAT --to-destination $INT_IP:$INT_PORT
iptables -t nat -A PREROUTING -p tcp -i qg-${QG_ID:0:11} --dport $EXT_PORT -j DNAT --to-destination $INT_IP:$INT_PORT
iptables -D FORWARD -p tcp -d $INT_IP --dport $INT_PORT -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -p tcp -d $INT_IP --dport $INT_PORT -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

exit
