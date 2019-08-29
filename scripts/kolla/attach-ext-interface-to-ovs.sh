#!/bin/bash
EXT_IF=eno1 # edit
EXT_IP=$(ip a show dev $EXT_IF | grep "inet " | grep -E -o  [0-9]+.[0-9]+.[0-9]+.[0-9]+/[0-9]+)
sudo ip add del $EXT_IP dev $EXT_IF
sudo docker exec -u 0 -it neutron_openvswitch_agent env EXT_IF=$EXT_IF bash
ovs-vsctl add-port br-ex $EXT_IF
exit
