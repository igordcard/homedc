#!/bin/bash
EXT_INTF_IP=eno1 # edit
sudo ip add del $EXT_INTF_IP dev eno1
sudo docker exec -u 0 -it neutron_openvswitch_agent bash
ovs-vsctl add-port br-ex $EXT_INTF_IP
exit