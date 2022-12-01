#!/bin/bash -xv
maas_server_admin=$2
maas_server_ip=$3
gateway_details=$4
DNS=$1

				 ssh -i /var/lib/jenkins/.ssh/id_rsa -o StrictHostKeyChecking=no $maas_server_admin@$maas_server_ip 'for filename in `ls -lrt /tmp/networking_test_output/| awk '{print $9}'`;
        do

                cat /tmp/networking_test_output/$filename >> /tmp/deployed_systems_network_status;
        done;
cat /tmp/deployed_systems_network_status;
mv /tmp/deployed_systems_network_status /tmp/deployed_systems_network_status_lastrun'
