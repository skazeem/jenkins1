#!/bin/bash
grep -B6 -i "mgmt_address" /home/playbooks/netplan/netplan-apply.yml | grep -i "hyd\|mgmt_address" | awk 'NR%2{a=$0;next}{print a","$0}' | sed 's/"//g;s/\/24//g;s/ //g' | awk -F ":" '{print $1":"$3}' > /var/lib/jenkins/openstack/ip_hostname

