#!/bin/bash -xv
server_list=$1

                if [ -z "$server_list" ]
                then

		 echo " INFO: Server list not provided by user, system will use the server list from most recently deployed nodes with os"
                        if [ -f /tmp/deploy_server ]
                                then
			 	dep_count=`cat /tmp/deploy_server| wc -l`
				if [ $dep_count -ne 0 ]
				then
                               echo -e "\nINFO: Below is the server list from latest run of OS deployment pipeline:\n`cat /tmp/deploy_server`" 
		       		else
				       echo -e "FATAL: there is some issue with file /tmp/deploy_server on MAAS  server containing list of deployed nodes from previous run"
			       exit 2
				fi	       
                        else
                                echo "FATAL:  User did not provide any server list and File /tmp/deploy_server on MAAS server with list of nodes with recent OS deployment is not available on the maas server, hence exiting the post deploy config"
                                exit 2
                        fi

                else
		echo -e "INFO: Server list  provided by user, system will post os configurations  on all nodes listed below\n"
                echo -e "$server_list"| tr " " "\n"
                fi

