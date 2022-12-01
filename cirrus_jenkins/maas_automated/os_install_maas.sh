#!/bin/bash -xv
maas_admin=$1
server_list=$6
pool=$3
os_codename=$4
os_name=$5
maas_server_ip=$2
server_count=`echo  $server_list|tr " " "\n" | wc -l`
echo $server_count
                        echo "creating MAAS API key"
                         api_key="`sudo maas apikey --username $maas_admin`"
                        echo " login into the MAAS url using the $api_key"
                         sudo maas login $maas_admin http://$maas_server_ip:5240/MAAS $api_key
                if [ $? -eq 0 ]; then
                        for server_details in `echo  $server_list| tr " " "\n"`
                                do read hostname domain mac_address power_admin power_pass power_ip_address <<<$(echo -e ${server_details} | awk -F "," '{print $1" "$2" "$3" "$4" "$5" "$6 }')
                                echo "$hostname $domain $mac_address $power_admin $power_pass $power_ip_address"

                              sudo maas $maas_admin  machines create hostname=$hostname fqdn=$hostname.$domain mac_addresses=$mac_address architecture=amd64 power_type=ipmi power_parameters_power_driver=LAN_2_0 power_parameters_power_user=$power_admin power_parameters_power_pass=$power_pass power_parameters_power_address=$power_ip_address power_parameters_power_boot_type=efi
                        done
                        declare -i ready_count=0
                        echo " $ready_count and $server_count"
                        while [ $ready_count -lt $server_count ]
                                do
                                echo " entering the while loop for sleep"
                                echo " $ready_count and $server_count"
 #                               ready_count=ready_count+1
                            ready_count=`sudo maas $maas_admin machines read | jq -r '.[] | .hostname + " " + .status_message + " " + .system_id'|  grep -i Ready| wc -l `
                                echo " $ready_count and $server_count"
                                echo "going in sleep state"
                                sleep 60
                        done
                      ## ready_server=`sudo maas $maas_admin machines read | jq -r '.[] | .hostname + " " .status_message + " " + .system_id'|  grep -i Ready`
                     sudo maas $maas_admin machines read | jq -r '.[] | .hostname + " " +.status_message + " " + .system_id'|  grep -i Ready > /tmp/ready_server
			sudo chmod 777 /tmp/ready_server
                        if  [ $ready_count -gt 0 ]
                                then
                                echo $ready_count
                               for system_id in `cat /tmp/ready_server| awk '{print $3}'`
                                       do
                               echo " allocating pool and system for system_id = $system_id  and  hostname =`cat /tmp/ready_server| grep -i $system_id | awk '{print $1}'`"
#                                       system_id=`grep -i`wk '{print $3}' $id`
                               sudo  maas $maas_admin machine update $system_id pool=$pool
                               sudo maas $maas_admin machines allocate system_id=$system_id
		       sudo maas $maas_admin machine deploy $system_id  distro_series=$os_codename osystem=$os_name
                               done	
                        else
                                echo " there is some issue with commissioning of all nodes"
                        fi
			echo "Waiting for completion of deployment for 45 minutes"
			sleep 1800
			declare -i deploy_count=0
                        echo " $deploy_count and $server_count"
                                echo " waiting for servers to be deployed "
                                echo " $deploy_count and $server_count"
                                #deploy_count=ready_count+1
					for system_id in `cat /tmp/ready_server| awk '{print $3}'`
					do 
						touch /tmp/deploy_server
                       				sudo maas $maas_admin machine  read $system_id | jq -r ' .hostname + " " +.status_message + " " + .system_id + " " + .hardware_info.system_vendor'|  grep -i Deployed >> /tmp/deploy_server
					  deploy_count=`cat /tmp/deploy_server| wc -l`
					done
                                echo " $deploy_count and $server_count"
                                echo "going in sleep state"
                                sleep 5
			echo -e "OS deployment on the below nodes is completed \n `grep -i deployed /tmp/deploy_server`\n\n" 
			echo -e "Check OS deployment on the below nodes manually \n `grep -v -i deployed /tmp/deploy_server`\n\n"
			cd /root/maaz-backup/netplan_update/
			for host_info in `cat /tmp/deploy_server| grep -i deployed |  awk '{print $1}'`
			do	

				ssh -o StrictHostKeyChecking=no ubuntu@$host_info sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys
				system_info=`grep -i $host_info /tmp/deploy_server | awk '{print $3}'`
				 hardware_vendor=`grep -i $host_info /tmp/deploy_server| awk '{print $4}'`
				 echo " system_id=:$system_info and hardware_vendor: $hardware_vendor "

				 ansible-playbook /root/maaz-backup/netplan_update/netplan-apply.yml -i hosts -l $host_info 
			#	cd /home/playbooks/netplan_update	
			#	if [ $hardware_vendor == HP ]
			#	then
			#		echo "Hardware vendor for server $host_info is $hardware_vendor"
			#		ansible-playbook netplan-uat-hp-cat-1.yml -i hosts -l $host_info
			#		if [ $? != 0  ]
			#		then
			#			ansible-playbook netplan-uat-hp-cat-2.yml -i hosts -l $host_info
			#		fi
			#
			#	elif [ $hardware_vendor == Dell ]
			#	then
			#		echo "Hardware vendor for server $host_info is $hardware_vendor"
			#		ansible-playbook netplan-uat-dell-storage.yml -i hosts -l $host_info
			#	else 
			#		echo "Unrecognized hardware vendor for server $host_info"
			#	fi
#				unset $system_info $hardware_vendor
			done			
		cd /tmp/
		mv /tmp/ready_server /tmp/ready_server_lastrun
		mv /tmp/deploy_server /tmp/deploy_server_lastrun
                else
                echo "MAAS login  failed"
                fi
		echo " keeping backup of ready and deployed server list under filename ready_server_lastrun and deploy_server_lastrun"
#		cd /tmp/
#		mv /tmp/ready_server /tmp/ready_server_lastrun
#		mv /tmp/deploy_server /tmp/deploy_server_lastrun
#
