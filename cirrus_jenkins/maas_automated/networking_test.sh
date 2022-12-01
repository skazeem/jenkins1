#!/bin/bash -xv

gateway_details=$3
maas_server_admin=$2
			
DNS="samay1.nic.in"

echo "$gateway_details"
for host_info in `cat /tmp/deploy_server_lastrun| grep -i deployed |  awk '{print $1}'`
                        do
                                 scp -o StrictHostKeyChecking=no /root/rakesh_network_test/bonding_test.sh $maas_server_admin@$host_info:/root/bonding_test.sh
                                 ssh -o StrictHostKeyChecking=no $maas_server_admin@$host_info 'chmod 766 /root/bonding_test.sh'
                                 if [[ $host_info =~ "infra" ]]; then
                                        echo "$host_info is infra"
                                        cat /root/.ssh/id_rsa.pub | ssh $maas_server_admin@$host_info "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
                                        scp -o StrictHostKeyChecking=no /root/.ssh/id_rsa root@$host_info:/root/.ssh/id_rsa
                                fi
                                #  ssh -o StrictHostKeyChecking=no root@$host_info</root/bonding_test.sh "$DNS" "$host_info" "$gateway_details"
                                ssh -o StrictHostKeyChecking=no $maas_server_admin@$host_info /root/bonding_test.sh "$DNS" "$host_info" "'$gateway_details'"
                                scp -o StrictHostKeyChecking=no $maas_server_admin@$host_info:/tmp/${host_info}_network_status_lastrun /tmp/networking_test_output/${host_info}_networking_test_output
echo " 1st loop `hostname`"
done


