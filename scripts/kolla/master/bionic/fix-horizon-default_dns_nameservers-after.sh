#!/bin/bash
# Some sort of bug/incompatibility between Horizon and Kolla (master/source)
# is making Horizon crash when opening the Create Network.
# The following` lines help temporarily fixing it in running deployments.
# Can also be done via horizon container but it will only last until it's restarted.
# 20190906
# See launchpad: https://bugs.launchpad.net/kolla-ansible/+bug/1843104
# See pastebin: http://paste.openstack.org/show/772115/

DNS1=8.8.8.8
DNS2=8.8.4.4
DNS3=208.67.222.222
LOCAL_SETTINGS="/etc/kolla/horizon/local_settings"
#LOCAL_SETTINGS="/etc/openstack-dashboard/local_settings"

#sudo docker exec -it horizon bash
sed "s/8.8.8.8/$DNS1/" $LOCAL_SETTINGS -i
sed "s/8.8.4.4/$DNS2/" $LOCAL_SETTINGS -i
sed "s/208.67.222.222/$DNS3/" $LOCAL_SETTINGS -i
sed "s/# 'default_dns_nameservers'/'default_dns_nameservers'/" $LOCAL_SETTINGS -i
#exit

sudo docker restart horizon
