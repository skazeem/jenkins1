#!/bin/bash
apt -y install python git python-dev
git clone https://github.com/ceph/ceph-ansible.git
cd ceph-ansible/
#git branch -r
git checkout version
apt -y install python3-pip
pip install -r requirements.txt
rm -rf /usr/share/ceph-ansible/ceph-ansible
cd ../
mv ceph-ansible /usr/share/ceph-ansible
rm -rf /etc/ansible
mkdir /etc/ansible/
ln -s /usr/share/ceph-ansible/group_vars /etc/ansible/group_vars
