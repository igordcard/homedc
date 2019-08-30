#!/bin/bash
# TODO: service file or some sort of post-boot script

ROUTER=demo-router # change according to external router's name
ROUTER_ID=$(openstack router show $ROUTER -f yaml | grep -E "^id" | cut -d ":" -f 2 | awk '{$1=$1;print}')
QG_ID=($(openstack port list -c id -c device_owner --device-id $ROUTER_ID | grep router_gateway | cut -d "|" -f 2 | awk '{$1=$1;print}' | xargs))
GW_PORT_ID=$(openstack port list -c id -c device_owner --device-id $ROUTER_ID | grep router_gateway | cut -d "|" -f 2 | awk '{$1=$1;print}')
INT_PORT_IDS=($(openstack port list -c id -c device_owner --device-id $ROUTER_ID | grep router_interface | cut -d "|" -f 2 | awk '{$1=$1;print}' | xargs))


# 1. make sure chameleonsocks is running (and stop systemd one first)
sudo systemctl stop redsocks
sudo ip netns exec qrouter-$ROUTER_ID env INT_PORT_IDS=$INT_PORT_IDS QG_ID=$QG_ID bash

# 2. fix iptables rules for chameleonsocks
for intf in "${INT_PORT_IDS[@]}"
do
 iptables -t nat -D PREROUTING -i qr-${intf:0:11} -p tcp -j CHAMELEONSOCKS
 iptables -t nat -A PREROUTING -i qr-${intf:0:11} -p tcp -j CHAMELEONSOCKS
done

# 3. guarantee dhclient is running for router ext interface
dhclient -v -4 -cf /etc/dhcp/dhclient.conf qg-${QG_ID:0:11}
exit
