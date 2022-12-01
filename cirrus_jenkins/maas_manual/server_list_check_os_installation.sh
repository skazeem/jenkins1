#!/bin/bash -xv
maas_server_ip=$1
maas_admin=$2
server_list=$3
	echo "INFO: creating MAAS API key"
                         api_key="`sudo maas apikey --username $maas_admin`"
                        echo "INFO: log in into the MAAS url using the $api_key"
                         sudo maas login $maas_admin http://$maas_server_ip:5240/MAAS $api_key
          if [ $? -eq 0 ]
	 	 then
                echo "INFO: MAAS login is working fine "

                if [ -z "$server_list" ]
                then
                        echo -e  " INFO: Server list not provided by user, system will deploy os on all nodes in ready and released state\n"
                        sudo maas $maas_admin  machines read | jq -r '.[] | .hostname + "," + .status_message + "," + .system_id'|  grep  -i "Ready\|Release"

                else
		echo -e "INFO: Server list  provided by user, system will deploy os on all nodes in ready and released state\n"
                echo -e "$server_list"| tr " " "\n"
                fi

	 else
		 echo -e " Unable to connect with Maas cli"
		 exit 2
	fi
