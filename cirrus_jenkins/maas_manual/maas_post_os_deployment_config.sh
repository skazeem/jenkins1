#!/bin/bash
username=$1
password=$2
server_list=$3
netplan_file=$4
host_inventory=$5
ntp_config=$6

#cat /dev/null &> /tmp/deploy_server_fail_lastrun

if [ -z $password ]
then
	echo -e "FATAL: password  parameter value is null, exiting the job. Please provide proper password for the $username to be created on the nodes"
	exit 2
else
		cat /dev/null &>/tmp/netplan_timezone_status

		cat /dev/null &> /tmp/server2_list

                if [ -z "$server_list" ]
                then
                        echo " INFO: Server list not provided by user, system will use the server list from most recently deployed nodes with os"
			if [ -f /tmp/deploy_server ]
				then
				cat /tmp/deploy_server > /tmp/server2_list
				list_server=previous_run
			else
				echo "FATAL:  User did not provide any server list and File /tmp/deploy_server with list of nodes with recent OS deployment is not available on the maas server, hence exiting the post deploy config"
				exit 2
			fi
                else
		echo -e "INFO: Server list is provided by user as \n$server_list"
		cat /dev/null &> /tmp/server2_list
                echo -e "$server_list"| tr " " "\n" > /tmp/server2_list
		list_server=user_provided
                fi
                server2_list=/tmp/server2_list
                echo -e "INFO: list of servers for OS deployment \n`cat $server2_list`"

                if [ -f $server2_list ] 
		then

		for host_info in `cat $server2_list | grep -i deployed |  awk -F "," '{print $1}'`
                       do

                               ssh -o StrictHostKeyChecking=no ubuntu@$host_info sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys
                               echo " Adding $username with user entered password  on $host_info"
                               ssh -o StrictHostKeyChecking=no root@$host_info sudo useradd -m $username  -s /bin/bash -G "sudo"
                               ssh  -o StrictHostKeyChecking=no root@$host_info 'echo -e "\$password\n\$password" | passwd $username'

				if [ $? -eq 0 ]
                               then
                                       echo "User $username created successfully on the node $host_info "

                               else
                                        echo "User $username not  created on the node $host_info "
					echo -e "FATAL: nicroot_user_creation\tFAILED\t$host_info">> /tmp/netplan_timezone_status
                                fi



			       if [[ $host_info =~ "controller" ]]
                               then
                                      echo "INFO: $host_info is a controller node copying root ssh keys from maas server to controler node"
                                  #     cat /root/.ssh/id_rsa.pub | ssh $maas_server_admin@$host_info "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
                                        scp -o StrictHostKeyChecking=no /root/.ssh/id_rsa $maas_server_admin@$host_info:/root/.ssh/id_rsa
                              fi
                                export ANSIBLE_HOST_KEY_CHECKING=False
                                ansible-playbook $netplan_file -i $host_inventory -l $host_info
				if [ $? -eq 0 ]
                               then
                                       echo "Netplan config deployed successfully  on the node $host_info "

                               else
                                        echo "netplan config deployment unseccsful on the node  $host_info "
                                        echo -e "FATAL: NETPLAN_APPLY\tFAILED\t$host_info">> /tmp/netplan_timezone_status
                                fi



				ansible-playbook $ntp_config -i $host_inventory -l $host_info

				if [ $? -eq 0 ]
                               then
                                       echo "Timezonoe config deployed successfully  on the node $host_info "

                               else
                                        echo "Timezone config deployment unseccsful on the node  $host_info "
                                        echo -e "FATAL: TIMEZONE_APPLY\tFAILED\t$host_info">> /tmp/netplan_timezone_status
                                fi
				

                 done
                       echo -e " INFO: keeping backup of server_list, ready and deployed list under filename *lastrun in /tmp directory"
                       cd /tmp/
		       
		       if [ -f /tmp/server1_list ]
		       then
                       		mv /tmp/server1_list /tmp/server1_list_lastrun
		       fi

		       if [ -f /tmp/server2_list ]
		       then
                     		 mv /tmp/server2_list /tmp/server2_list_lastrun
		       fi
		       
		       if [ -f /tmp/ready_server ]
		       then
                       		 mv /tmp/ready_server /tmp/ready_server_lastrun
		       fi
		       
		       if [ -f /tmp/deploy_server ]
		       then
                       mv /tmp/deploy_server /tmp/deploy_server_lastrun
		       fi
		       
		       if [ $list_server == "user_provided" ]
		       then
			       cp /tmp/server2_list_lastrun /tmp/deploy_server_lastrun
		       fi
		       
		       if [ -f /tmp/deploy_server1 ]
		       then
                       		mv /tmp/deploy_server1 /tmp/deploy_server1_lastrun
		       fi
		       
		       if [ -f /tmp/deploy_server2 ]
		       then
                       		mv /tmp/deploy_server2 /tmp/deploy_server2_lastrun
		       fi
		       
		       if [ -f /tmp/deploy_server_fail ]
		       then
                       		mv /tmp/deploy_server_fail /tmp/deploy_server_fail_lastrun
		       fi
		       count=`cat /tmp/netplan_timezone_status | wc -l`
		       if [ $count -gt 0 ]
		       then 
			       echo -e "Failed to deploy configs on below hosts\n`cat /tmp/netplan_timezone_status`"
			       exit 2
			else

		       echo -e "INFO: You can use below server list as  input for next Automation of Networking testing in Pipeline 1.4_MAAS_AUTOMATION_POST_CONFIG_CHECK \n\n`cat /tmp/deploy_server_lastrun`\n\n"
		       fi
		else 
			echo " FATAL: could not retrieve list of nodes to apply netplan config"
			exit 2
		fi
fi
