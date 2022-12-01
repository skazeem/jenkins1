#!/bin/bash -xv
maas_admin=$1
server_list=$3
maas_server_ip=$2
#server_count=2

cat /dev/null > /tmp/server_list
 

#echo " Total Number of Servers to be deployed $server_count"
                        echo "creating MAAS API key"
                         api_key="`sudo maas apikey --username $maas_admin`"
                        echo " login into the MAAS url using the $api_key"
                         sudo maas login $maas_admin http://$maas_server_ip:5240/MAAS $api_key
          if [ $? -eq 0 ]; then
		if [ -z "$server_list" ]
		then
		echo "INFO: Server list is not provided by user"
		sudo maas $maas_admin  machines read | jq -r '.[] | .hostname + "," + .status_message + "," + .system_id'|  grep  -i New > /tmp/server_list
		else
		echo "INFO: using user provided server list"
		echo -e "$server_list"| tr " " "\n"  > /tmp/server_list
		fi
		enlisted_server=`cat /tmp/server_list | wc -l`
		server_count=`cat /tmp/server_list | wc -l`
		echo -e "INFO: Below is the list of servers to be commissioned \n`cat /tmp/server_list`"
		if [[ "$server_count" -gt 0 ]]
		then
				echo "INFO: Commissioning  $server_count servers  enliseted as New in MAAS"
					for system_id in `cat /tmp/server_list| awk -F "," '{print $3}'`
					do
					#sudo maas $maas_admin  machines accept-all &> /dev/null  ## change made and added below line to allow selected enlisted machine to be commisioned
					sudo maas $maas_admin machine  commission $system_id &> /dev/null

					echo " INFO: Commisioning Node :`cat /tmp/server_list| grep -i  $system_id | awk -F "," '{Print $1":" $2}'`"
					done
		if [ $? -eq 0 ]; then

################# Code to set the hostname after the identifies is provided 
#			for server_details in `echo  $server_list| tr " " "\n" | awk '{print $3}'
#			 do
#
#				sudo maas $maas_admin machine update $system_details hostname=`hostname - command`
#                        done

                        declare -i ready_count=0
			declare -i counta=0
     #                   echo " Count of Server in Ready state: $ready_count and Total count of servers to be commissioned: $server_count"
                        while [[ "$ready_count" -lt "$server_count" && "$counta" -lt 10 ]]
                                do
                                echo "INFO: Current servers in ready state pre status check: $ready_count and Total server count :$server_count and Loop count: $counta"
                                echo "INFO: going in sleep state for 2 minutes"
                                sleep 120
                                counta=counta+1
				cat /dev/null>/tmp/commission_list
				for system_id in `cat /tmp/server_list| awk -F "," '{print $3}'`
				do
                                sudo maas $maas_admin machine read $system_id| jq -r ' .hostname + "," + .status_message + "," + .system_id'|  grep -i Ready >> /tmp/commission_list 
				done
				ready_count=`cat /tmp/commission_list|wc -l`
                                echo "INFO: Current servers in ready state post status check: $ready_count and Expected server count: $server_count"
                        done

					
					for system_id in `cat /tmp/server_list| awk -F "," '{print $3}'`
					do 
						sudo maas $maas_admin machine  read $system_id | jq -r ' .hostname + "," +.status_message + "," + .system_id'|  grep -v -i ready  >> /tmp/commission_list_fail
					done
					commission_fail=`cat /tmp/commission_list_fail | wc -l`
					if [ $commission_fail -gt 0 ]
					then
					echo -e "INFO: Few nodes are properly commissioned and in ready state, you can use the below list of servers as input for next pipeline  1.2MAAS_job_Manual_OS_Deploy_Only \n`cat /tmp/commission_list`"
					echo -e " FATAL: Check commissioning on the below nodes manually \n `cat /tmp/commission_list_fail`"
					exit 2
					else
					echo -e  "INFO:  All nodes are properly commissioned and in ready state, you can use the below list of servers as input for next pipeline  1.2MAAS_job_Manual_OS_Deploy_Only \n`cat /tmp/commission_list`"
					fi
				
			cd /tmp/
			mv /tmp/commission_list_fail /tmp/commission_list_fail_lastrun_`date +%d-%m-%Y`
			mv /tmp/commission_list /tmp/commission_list_lastrun_`date +%d-%m-%Y`
			 mv /tmp/server_list /tmp/server_list_lastrun
			#mv /tmp/ready_server /tmp/ready_server_lastrun
			#mv /tmp/deploy_server /tmp/deploy_server_lastrun
			#mv /tmp/deploy_server_fail /tmp/deploy_server_fail_lastrun
			
                        else
                                echo " FATAL: there is some issue with commissioning of all nodes"
				exit 2
                        fi
		  else 
			  echo " WARNING: No enlisted nodes found for allocation"
			  exit 2
		  fi
	  	
	else 
		echo " FATAL: maas login failed"
		exit 2
	fi

	#	echo " keeping backup of ready and deployed server list under filename ready_server_lastrun and deploy_server_lastrun"
