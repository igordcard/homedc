#!/bin/bash
### kolla-prep: Igor D.C.           ###
### kolla-ansible, all-in-one       ###
### stein, bionic, source           ###
### v2, as of 20190615+             ### 
### not tested as single executable ###
### run as normal user              ###

cd

sudo apt-get update
sudo apt-get install build-essential virtualenv python-virtualenv python-dev libffi-dev gcc libssl-dev python-selinux python-setuptools -y

virtualenv --clear homedc
source homedc/bin/activate
pip install -U pip ansible

# kolla-ansible source installation (better for development)
git clone https://github.com/openstack/kolla
git clone https://github.com/openstack/kolla-ansible
pip install -r kolla/requirements.txt
pip install -r kolla-ansible/requirements.txt

# init configs
rm -rf /etc/kolla
sudo mkdir -p /etc/kolla
sudo cp -r kolla-ansible/etc/kolla/* /etc/kolla
sudo chown -R $USER:$USER /etc/kolla
cp kolla-ansible/ansible/inventory/* .

# ansible configuration
sudo mv /etc/ansible/ansible.cfg /etc/ansible/ansible.cfg.bak
sudo touch /etc/ansible/ansible.cfg
sudo bash -c 'cat <<EOT > /etc/ansible/ansible.cfg
[defaults]
host_key_checking=False
pipelining=True
forks=100
EOT'

# generate new /etc/kolla/passwords.yml
./kolla-ansible/tools/generate_passwords.py

# this section is high-risk for failure due to possible sample changes,
# make sure all substitutions succeeded when troubleshooting something:
sed -i 's/#kolla_base_distro: \"centos\"/kolla_base_distro: \"ubuntu\"/' /etc/kolla/globals.yml
sed -i 's/#kolla_install_type: \"binary\"/kolla_install_type: \"source\"/' /etc/kolla/globals.yml
sed -i 's/#openstack_release: \"\"/openstack_release: \"stein\"/' /etc/kolla/globals.yml
sed -i 's/kolla_internal_vip_address: \"10.10.10.254\"/kolla_internal_vip_address: \"192.168.2.20\"/' /etc/kolla/globals.yml
sed -i 's/#network_interface: \"eth0\"/network_interface: \"enp1s0\"/' /etc/kolla/globals.yml
sed -i 's/#neutron_external_interface: \"eth1\"/neutron_external_interface: \"ens5f3\"/' /etc/kolla/globals.yml
sed -i 's/#enable_haproxy: \"yes\"/enable_haproxy: \"no\"/' /etc/kolla/globals.yml

# and install docker-ce manually, with the following steps
sudo apt-get remove docker docker-engine docker.io containerd runc -y
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

# get kolla running (if sudo expires in-between the commands, re-run sudo manually just to refresh)
./kolla-ansible/tools/kolla-ansible -i ./all-in-one bootstrap-servers
./kolla-ansible/tools/kolla-ansible -i ./all-in-one prechecks
# and finally deploy
./kolla-ansible/tools/kolla-ansible -i ./all-in-one deploy
# post installation
./kolla-ansible/tools/kolla-ansible -i ./all-in-one post-deploy
source /etc/kolla/admin-openrc.sh
# configure public flat network addressing
sed -i 's/10.0.2.0\/24/192.168.3.0\/24/' kolla-ansible/tools/init-runonce
sed -i 's/start=10.0.2.150,end=10.0.2.199/start=192.168.3.50,end=192.168.3.99/' kolla-ansible/tools/init-runonce
sed -i 's/10.0.2.1/192.168.3.1/' kolla-ansible/tools/init-runonce
# CLI
pip install -U python-openstackclient python-glanceclient python-neutronclient
# create basic OpenStack resources (uses CLI above)
./kolla-ansible/tools/init-runonce


# To destroy:

# source homedc/bin/activate
# ./kolla-ansible/tools/kolla-ansible -i ./all-in-one destroy --yes-i-really-really-mean-it
# sudo rm -rf /etc/kolla/
# deactivate
# rm -rf homedc
