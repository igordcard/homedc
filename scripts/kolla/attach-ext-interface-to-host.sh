#!/bin/bash
EXT_IF=eno1 # edit
sudo docker exec -u 0 -it neutron_openvswitch_agent env EXT_IF=$EXT_IF bash
ovs-vsctl del-port br-ex $EXT_IF
exit
sudo netplan apply # bionic+
