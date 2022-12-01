#!/bin/bash -xv
maas_admin=$1
maas_server_ip=$2
os_name=$3
os_codename=$4
server_list=$5

                        echo "INFO: creating MAAS API key"
                         api_key="`sudo maas apikey --username $maas_admin`"
                        echo "INFO: log in into the MAAS url using the $api_key"
                         sudo maas login $maas_admin http://$maas_server_ip:5240/MAAS $api_key
          if [ $? -eq 0 ]; then
		echo "INFO: MAAS login is working fine "

		if [ -z "$server_list" ]
		then
			echo " INFO: Server list not provided by user, system will deploy os on all nodes in ready and released state"
			sudo maas $maas_admin  machines read | jq -r '.[] | .hostname + "," + .status_message + "," + .system_id'|  grep  -i "Ready\|Released" > /tmp/server1_list
		else
		echo -e "$server_list"| tr " " "\n" > /tmp/server1_list
		fi
		server1_list=/tmp/server1_list
		echo -e "INFO: list of servers for OS deployment \n `cat $server1_list`"
		server_count=`cat /tmp/server1_list|wc -l`
		
		if [ -f $server1_list ]; then
			touch /tmp/ready_server
			cat /dev/null &>/tmp/ready_server
			chmod 766 /tmp/ready_server
			for system_uid in `cat /tmp/server1_list| awk -F "," '{print $3}'`
			do 
                      ## ready_server=`sudo maas $maas_admin machines read | jq -r '.[] | .hostname + " " .status_message + " " + .system_id'|  grep -i Ready`
                     sudo maas $maas_admin machine read $system_uid | jq -r ' .hostname + "," +.status_message + "," + .system_id'|  grep -i "Ready\|Released" >> /tmp/ready_server
	     		done
			sudo chmod 777 /tmp/ready_server
			ready_count=`cat /tmp/ready_server | wc -l`
                        if  [ $ready_count -gt 0 ]
                                then
                               # echo $ready_count
                               for system_id in `cat /tmp/ready_server| awk -F "," '{print $3}'`
                                       do
                               		echo "INFO:  allocating system with system_id = $system_id  and  hostname = `cat /tmp/ready_server| grep -i $system_id | awk -F "," '{print $1}'`"
#                                       system_id=`grep -i`wk '{print $3}' $id`
#                               sudo  maas $maas_admin machine update $system_id pool=$pool
                               		sudo maas $maas_admin machines allocate system_id=$system_id &> /dev/null
		       			sudo maas $maas_admin machine deploy $system_id  distro_series=$os_codename osystem=$os_name &> /dev/null
                               done	
                       # else
                       #        echo " there is some issue with commissioning of all nodes"
                       # fi
			echo "INFO: Waiting for completion of deployment for 15 minutes "
			sleep 900
			declare -i deploy_count=0
			declare -i deploy_count1=0
			declare -i count=0
			touch /tmp/deploy_server
			touch /tmp/deploy_server1
			cat /dev/null>/tmp/deploy_server 
			cat /dev/null>/tmp/deploy_server1 
			                for system_id in `cat /tmp/ready_server| awk -F "," '{print $3}'`
                                       do

					sudo maas $maas_admin machine  read $system_id | jq -r ' .hostname + "," +.status_message + "," + .system_id'|  grep -i Deployed >> /tmp/deploy_server1
					done
					
					deploy_count1=`cat /tmp/deploy_server1| wc -l`
					
			if [[ $deploy_count1 -lt $server_count ]]
			then
			echo -e "INFO: Deploy count $deploy_count1  is less than the total server count $server_count"

			while [[ $deploy_count1 -lt $server_count && $count -lt 10 ]]
			do
		#		      cat /dev/null>/tmp/deploy_server1 
                        	echo "INFO: Loop count: $count , sleeping system for 1 minnutes"
                                echo "INFO: waiting for $server_count  servers deployment to be completd"
				sleep 60
				      for system_id in `cat /tmp/ready_server| awk -F "," '{print $3}'`
                                       do

                                        sudo maas $maas_admin machine  read $system_id | jq -r ' .hostname + "," +.status_message + "," + .system_id'|  grep -i Deployed >> /tmp/deploy_server1
                                        done
					deploy_count1=`cat /tmp/deploy_server1| wc -l`
				echo " system will wait for 10 more minutes to complete the deployment"
				count=count+1
			done
			else
				echo " INFO: $deploy_count1 servers are now deployed"
			fi

                                #deploy_count=ready_count+1
					
					for system_id in `cat /tmp/ready_server| awk -F "," '{print $3}'`
					do 
						sudo maas $maas_admin machine  read $system_id | jq -r ' .hostname + "," +.status_message + "," + .system_id'|  grep -i Deployed >> /tmp/deploy_server
						
					
					  deploy_count=`cat /tmp/deploy_server| wc -l`
                                	echo " INFO: Deployed server count: $deploy_count and Total server count: $server_count and loop count: $count"
					
                             #		sleep 60
					done
					if [ $deploy_count -gt 0 ]
					then	
					echo -e "INFO: OS deployment on the below nodes is completed, you copy paste the below list in server_list input of next pipeline to configure ssh keys and netplan \n`cat /tmp/deploy_server| grep -i deployed`\n\n" 
					else 
					echo "FATAL: failed to deploy all the nodes"
					exit 2
					fi

					for system_id in `cat /tmp/ready_server| awk -F "," '{print $3}'`
					do 
						sudo maas $maas_admin machine  read $system_id | jq -r ' .hostname + "," +.status_message + "," + .system_id + "," + .hardware_info.system_vendor'|  grep -v  -i Deployed >> /tmp/deploy_server_fail
				
					done
					fail_count=`cat /tmp/deploy_server_fail|wc -l`
					if [ $fail_count -gt 0	]
					then
					echo -e "FATAL: Check OS deployment on the below nodes manually \n `cat /tmp/deploy_server_fail`"
					exit 2
					fi
#		for host_info in `cat /tmp/deploy_server| grep -i deployed |  awk -F "," '{print $1}'`
#			do	
#
#				ssh -o StrictHostKeyChecking=no ubuntu@$host_info sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys
#				echo " Adding $username with user entered password  on $host_info"
#				ssh -o StrictHostKeyChecking=no root@$host_info sudo useradd $username -s /bin/bash -G "sudo"
#				ssh  -o StrictHostKeyChecking=no root@$host_info 'echo -e "\$password\n\$password" | passwd $username'


#				system_info=`grep -i $host_info /tmp/deploy_server | awk -F ","  '{print $3}'`
#				 echo " system_id: $system_info and hostname: $hardware_vendor "
#                                export ANSIBLE_HOST_KEY_CHECKING=False
#				 ansible-playbook $netplan_file -i $host_inventory -l $host_info 
#
#			done			
#			echo " keeping backup of server_list, ready and deployed list under filename *lastrun "
#			cd /tmp/
#
#			mv /tmp/server1_list /tmp/server1_list_lastrun
#			mv /tmp/ready_server /tmp/ready_server_lastrun
#			mv /tmp/deploy_server /tmp/deploy_server_lastrun
#			mv /tmp/deploy_server1 /tmp/deploy_server1_lastrun
#			mv /tmp/deploy_server_fail /tmp/deploy_server_fail_lastrun
			
                        else
                                echo "FATAL: there is some issue with commissioning of all nodes"
				exit 2
                        fi
		else
			echo "FATAL: the file with list of nodes $server1_list is not present"
			exit 2
	  	fi
	else 
		echo "FATAL: maas login failed"
		exit 2
	fi
	#	echo " keeping backup of ready and deployed server list under filename ready_server_lastrun and deploy_server_lastrun"
