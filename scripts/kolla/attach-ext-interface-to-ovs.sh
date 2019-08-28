#!/bin/bash
EXT_INTF_IP=eno1 # edit
sudo docker exec -u 0 -it neutron_openvswitch_agent bash
ovs-vsctl del-port br-ex $EXT_INTF_IP
exit
sudo netplan appy # bionic+