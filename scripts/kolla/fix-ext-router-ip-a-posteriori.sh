#!/bin/bash

ROUTER=demo-router # change according to external router's name
ROUTER_ID=$(openstack router show $ROUTER -f yaml | grep -E "^id" | cut -d ":" -f 2 | awk '{$1=$1;print}')
QG_ID=($(openstack port list -c id -c device_owner --device-id $ROUTER_ID | grep router_gateway | cut -d "|" -f 2 | awk '{$1=$1;print}' | xargs))
QG_MAC=$(openstack port list -c mac_address -c device_owner --device-id $ROUTER_ID | grep router_gateway | cut -d "|" -f 2 | awk '{$1=$1;print}')

sudo ip netns exec qrouter-$ROUTER_ID env QG_ID=$QG_ID bash
# dhclient will keep running in the background too, in order to get the leases renewed:
dhclient -v -4 -cf /etc/dhcp/dhclient.conf qg-${QG_ID:0:11}
exit

NEW_IP=$(cat /var/log/syslog | grep "bound to" | tail -1 | grep -Eo  [0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)

ROUTER_ID=$(openstack router show $ROUTER -f yaml | grep -E "^id" | cut -d ":" -f 2 | awk '{$1=$1;print}')

EXT_INFO=$(openstack router show $ROUTER | grep external_gateway_info)
NET_ID=$(echo $EXT_INFO | sed 's/.*"network_id": "\([a-f0-9-]*\)".*/\1/')
SUBNET_ID=$(echo $EXT_INFO | sed 's/.*"subnet_id": "\([a-f0-9-]*\)".*/\1/')
openstack router set --external-gateway $NET_ID --fixed-ip subnet=$SUBNET_ID,ip-address=$NEW_IP $ROUTER
