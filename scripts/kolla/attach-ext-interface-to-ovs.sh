#!/bin/bash
sudo docker exec -u 0 -it neutron_openvswitch_agent bash
ovs-vsctl del-port br-ex eno1
exit
sudo netplan appy # bionic+
