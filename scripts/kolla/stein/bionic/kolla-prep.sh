#!/bin/bash
### kolla-ansible, all-in-one + designate, ###
### source, stein, bionic, as of 20190408  ###

# dependencies
sudo apt-get update
sudo apt-get install python-pip -y
sudo pip install -U pip
sudo apt-get install python-dev libffi-dev gcc libssl-dev python-selinux python-setuptools -y
sudo apt-get install software-properties-common -y
sudo apt-add-repository --yes ppa:ansible/ansible
sudo apt-get update
sudo apt-get install ansible -y

# ansible configuration
sudo touch /etc/ansible/ansible.cfg
sudo bash -c 'cat <<EOT > /etc/ansible/ansible.cfg
[defaults]
host_key_checking=False
pipelining=True
forks=100
EOT'

# kolla-ansible source installation (better for development)
git clone https://github.com/openstack/kolla -b stable/stein
git clone https://github.com/openstack/kolla-ansible -b stable/stein
sudo pip install -r kolla/requirements.txt
sudo pip install -r kolla-ansible/requirements.txt
cd kolla
sudo python setup.py install
cd ../kolla-ansible
sudo python setup.py install
cd

# basic configuration
sudo mkdir -p /etc/kolla
sudo cp -r kolla-ansible/etc/kolla/* /etc/kolla
sudo cp kolla-ansible/ansible/inventory/* .
cd kolla-ansible/tools
sudo ./generate_passwords.py
cd

# this section is high-risk for failure due to possible sample changes,
# make sure all substitutions succeeded when troubleshooting something:
sudo sed -i 's/#kolla_base_distro: \"centos\"/kolla_base_distro: \"ubuntu\"/' /etc/kolla/globals.yml
sudo sed -i 's/#kolla_install_type: \"binary\"/kolla_install_type: \"source\"/' /etc/kolla/globals.yml
sudo sed -i 's/#openstack_release: \"\"/openstack_release: \"stein\"/' /etc/kolla/globals.yml
sudo sed -i 's/kolla_internal_vip_address: \"10.10.10.254\"/kolla_internal_vip_address: \"192.168.2.100\"/' /etc/kolla/globals.yml
sudo sed -i 's/#network_interface: \"eth0\"/network_interface: \"enp1s0\"/' /etc/kolla/globals.yml
sudo sed -i 's/#neutron_external_interface: \"eth1\"/neutron_external_interface: \"ens5f3\"/' /etc/kolla/globals.yml

# additional configuration - designate
sudo sed -i 's/#enable_designate: \"no\"/enable_designate: \"yes\"/' /etc/kolla/globals.yml
sudo sed -i 's/#designate_backend: \"bind9\"/designate_backend: \"bind9\"/' /etc/kolla/globals.yml
sudo sed -i 's/#designate_ns_record: \"sample.openstack.org\"/designate_ns_record: \"homedc.local\"/' /etc/kolla/globals.yml
sudo mkdir -p /etc/kolla/config/designate/
# a bunch of other configs have to be done outside of this deployment script, see:
# https://docs.openstack.org/kolla-ansible/latest/reference/networking/designate-guide.html

# and install docker-ce manually, with the following steps
# (this was for kolla-ansible 7.0.1 though, so it might not be needed anymore using stable/stein):
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

# remove old easy_install dependency that no longer works with 18.04
sudo sed -i 's/easy_install/pip/' /usr/local/share/kolla-ansible/ansible/roles/baremetal/tasks/install.yml

# get kolla running
sudo kolla-ansible -i ./all-in-one bootstrap-servers
sudo kolla-ansible -i ./all-in-one prechecks
# temporary workaround to probable bug:
sudo sed -i "1s/^/127.0.0.1 $HOSTNAME\n/" /etc/hosts
# and finally deploy
sudo kolla-ansible -i ./all-in-one deploy

# post installation
sudo pip install python-openstackclient python-glanceclient python-neutronclient
sudo kolla-ansible -i ./all-in-one post-deploy
. /etc/kolla/admin-openrc.sh
. kolla-ansible/tools/init-runonce
# at this point take care of the designate configurations via cli
# TODO: add such configurations here as well
