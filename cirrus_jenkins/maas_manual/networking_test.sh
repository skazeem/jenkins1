#!/bin/bash  

maas_server_admin=$1
gateway_details_storage=$2
server_list=$3
date=`date '+%Y/%m/%d_%H:%M:%S'`
gateway_details_openstack=$4
bond_speed=$5
# echo "creating MAAS API key"
 #                        api_key="`sudo maas apikey --username $maas_admin`"
 #                       echo " login into the MAAS url using the $api_key"
 #                        sudo maas login $maas_admin http://$maas_server_ip:5240/MAAS $api_key
 #         if [ $? -eq 0 ]; then
			
#DNS="maas $maas_admin maas get-config name=upstream_dns| jq -r"
DNS_TEST='email.gov.in'
#echo "$DNS"

echo -e "\nINFO: maas_server_admin $maas_server_admin \n\n server_list: $server_list "
echo -e "\nGateway details for storage_nodes: $gateway_details_storage\n Gateway details for non_storage_nodes:$gateway_details_openstack"
if [ -d /tmp/networking_test_output ]
then 
echo "INFO: Network output directory is already present"
else
  echo  "INFO: Creating /tmp/networking_test_output  directory on maas server 	"
       	cd /tmp
    	mkdir networking_test_output
fi

if [ -z "$server_list" ]
then
	echo "INFO: Server list is not provided using server list provided for most recent post os deploy configuration"
	cp /tmp/deploy_server_lastrun /tmp/post_check_server_list
	server1_list=/tmp/post_check_server_list

else
	echo " INFO: using user proivded server list for performing checks"
	echo -e "$server_list"| tr " " "\n" > /tmp/post_check_server_list
	server1_list=/tmp/post_check_server_list
fi
echo -e "INFO: Cleaning up file already present in path /tmp/networking_test_output/"

	for filename in `ls -lrt /tmp/networking_test_output/| awk '{print $9}'`
        do

          #      cat  /dev/null &>/tmp/networking_test_output/$filename
	  	mv /tmp/networking_test_output/$filename /tmp/networking_test_output_old/
        done


echo -e "INFO: Below is the list of servers on which the checks will be performed\n`cat $server1_list`"
	for host_info in `cat $server1_list| grep -i deployed |  awk -F "," '{print $1}'`
                        do
				echo "INFO: Setting up pre-requisuite scripts on the host $host_info for performing config checks"
				 if [[ $host_info =~ "s-controller" || $host_info =~ "s-osd" ]]
			 		then
						gateway_details=$gateway_details_storage

						  echo -e "export DNS_TEST=$DNS_TEST\nexport host_info=$host_info\nexport gateway_details=$gateway_details\nexport server_type=storage\nexport bond_speed=$bond_speed\nexport MGMT_SSH=NOT_APPLICABLE\nexport mgmt_addrs=NOT_APPLICABLE">/tmp/network_test_variables
#						 echo -e "export DNS_TEST=$DNS_TEST\nexport host_info=$host_info\nexport gateway_details=$gateway_details\nexport server_type=storage\nexport bond_speed=$bond_speed">/tmp/network_test_variables
					 else
						  gateway_details=$gateway_details_openstack
#						  mgmt_addrs=`grep -i  "${host_info}\|mgmt_address" /home/playbooks/netplan/netplan-apply.yml |  head -2 |awk 'NR%2{a=$0;next}{print a","$0}' | sed 's/"//g;s/\/24//g;s/ //g' | awk -F ":" '{print $3}'`
	#					 mgmt_addrs=`grep -A8 -i  "$host_info" /home/playbooks/netplan/netplan-apply.yml | grep -v gateway | grep -i "${host_info}\|br_mgmt\|address"|awk 'NR%3{a=$0;next}{print a","$0}' | sed 's/"//g;s/\/24//g;s/ //g' | awk -F ":" '{print $3}'`
						  mgmt_addrs=`grep -i  "${host_info}\|mgmt_address" /home/playbooks/netplan/netplan-apply.yml  | grep -A1 $host_info| awk 'NR%2{a=$0;next}{print a","$0}' | sed 's/"//g;s/\/24//g;s/ //g' | awk -F ":" '{print $3}'`
						  ssh  -o StrictHostKeyChecking=no $mgmt_addrs exit
						  if [ $? -eq 0 ]
						  then 
							  MGMT_ADDRESS=Success
						  else
							   MGMT_ADDRESS=Fail
						  fi

						  echo -e "export DNS_TEST=$DNS_TEST\nexport host_info=$host_info\nexport gateway_details=$gateway_details\nexport server_type=openstack\nexport bond_speed=$bond_speed\nexport MGMT_SSH=$MGMT_ADDRESS\nexport mgmt_addrs=$mgmt_addrs">/tmp/network_test_variables
					fi


                                 scp -o StrictHostKeyChecking=no /tmp/network_test_variables $maas_server_admin@$host_info:/root/network_test_variables &> /dev/null
                                 scp -o StrictHostKeyChecking=no /var/lib/jenkins/maas_manual/bonding_test.sh $maas_server_admin@$host_info:/root/bonding_test.sh &> /dev/null
                                 scp -o StrictHostKeyChecking=no /var/lib/jenkins/maas_manual/config_testing.sh $maas_server_admin@$host_info:/root/config_testing.sh &> /dev/null
                                 ssh -o StrictHostKeyChecking=no $maas_server_admin@$host_info 'chmod 766 /root/bonding_test.sh' &> /dev/null
                                 ssh -o StrictHostKeyChecking=no $maas_server_admin@$host_info 'chmod 766 /root/config_testing.sh' &> /dev/null
                                  # ssh -o StrictHostKeyChecking=no $maas_server_admin@$host_info 'nohup /root/bonding_test.sh > /dev/null 2>&1 &'
                               #   ssh -o StrictHostKeyChecking=no $maas_server_admin@$host_info  'nohup bash /root/bonding_test.sh > /dev/null &  && exit'
                                 ssh -o StrictHostKeyChecking=no $maas_server_admin@$host_info /root/config_testing.sh &> /dev/null

                                #scp -o StrictHostKeyChecking=no $maas_server_admin@$host_info:/tmp/${host_info}_network_status_lastrun /tmp/networking_test_output/${host_info}_networking_test_output
				echo -e "INFO: Config test in progress for host $host_info" 
	done
	echo -e "INFO: As  the execution of bond failover takes minimum of 25 minutes process will go in sleep state for 25 minutes"
	sleep 1620
	        for host_info in `cat $server1_list| grep -i deployed |  awk -F "," '{print $1}'`
                        do
#			 if [ -f  /tmp/networking_test_output/${host_info}_networking_test_output ]
#			 then 
#				 echo -e "Truncating old file  /tmp/networking_test_output/${host_info}_networking_test_output"
#				 cat /dev/null &> /tmp/networking_test_output/${host_info}_networking_test_output 
#			 scp -o StrictHostKeyChecking=no $maas_server_admin@$host_info:/tmp/${host_info}_network_status_lastrun /tmp/networking_test_output/${host_info}_networking_test_output
#			else
			 scp -o StrictHostKeyChecking=no $maas_server_admin@$host_info:/tmp/${host_info}_network_status_lastrun /tmp/networking_test_output/${host_info}_networking_test_output
#			fi
	        done
		if [ -f /tmp/post_check_server_list ]
		then
		echo "INFO: Moving the server_list details in a file with name /tmp/post_check_server_list_lastrun "
		mv /tmp/post_check_server_list /tmp/post_check_server_list_lastrun
		fi
       #else 
	#       echo " unable to gather the DNS info, terminating the network test"
#fi

