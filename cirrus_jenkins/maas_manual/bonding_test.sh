#!/bin/bash

date=`date '+%Y/%m/%d_%H:%M:%S'`
source /root/network_test_variables
mtu=`grep -i mtu /etc/netplan/50-cloud-init.yaml | sort -nr  -k2| uniq| head -1 |awk '{print $2}'`

mtu_size=$((mtu - 50))
echo $mtu_size

function gateway_test() {

		       	preferred_gateway1=`ip r | head -1 | awk '{print $3"_"$5}'`
	if [ $server_type == "storage" ] 
		then 
			echo $server_type
		       	preferred_gateway=`ip r | head -1 | awk '{print $5}'`
		       	echo $preferred_gateway 
			if [[ "$preferred_gateway" == "storage-ext" ]]
				then
					 echo -e "INFO:\t$server_type\t$preferred_gateway1\tCORRECT_GATEWAY">>/tmp/${host_info}_network_status

			else
					 echo -e "WARNING:\t$server_type\t$preferred_gateway1\tGATEWAY_MISMATCH">>/tmp/${host_info}_network_status
			fi
		else
		       	echo $server_type
			preferred_gateway=`ip r | head -1 | awk '{print $5}'`
			if [[ "$preferred_gateway" == "br-mgmt" ]]
				then
					 echo -e "INFO:\t$server_type\t$preferred_gateway1\tCORRECT_GATEWAY">>/tmp/${host_info}_network_status

			else
					 echo -e "WARNING:\t$server_type\t$preferred_gateway1\tGATEWAY_MISMATCH">>/tmp/${host_info}_network_status
			fi

		fi

}



function dns_test() {


	nslookup $DNS_TEST &> /dev/null
        if [ $? -eq 0 ]
        then

        echo -e "INFO:\t$host_info\t \tDNS_Reachable" >>/tmp/${host_info}_network_status

        else
        echo -e "FATAL:\t$host_info\t \tDNS_NOT_Reachable ">>/tmp/${host_info}_network_status
	fi
}


function ntp_test() {
	NTP_STATUS=`sudo chronyc tracking | grep -i "Leap status" | awk -F ":" '{print "NTP_SYNC:" $2}'`
	if [ "$NTP_STATUS" == "NTP_SYNC: Normal" ]
		then
		echo -e  "INFO:\t$NTP_STATUS" >> /tmp/${host_info}_network_status
	else
		echo -e "WARNING:\t$NTP_STATUS" >> /tmp/${host_info}_network_status
	fi
    }


function bond_list() {

                echo -e "INFO: list of bonds to test for failover not provided. Checking if bond is present on the host"
                bond_count=`ls -lrt /proc/net/bonding/ | grep -i bond |wc -l`
                if [ $bond_count -gt 0 ]
                then
                echo -e "INFO: Getting list of bonds"

                   export  bond_number=`ls -lrt /proc/net/bonding/ | awk '{print $9}'  | grep -i bond | tr "\n" ","`
                        echo "INFO: list of bonds = $bond_number"
                else
                        echo "WARNING: No Bonds for failover test" >>/tmp/${host_info}_network_status
                fi
}

function enable_lldp() {


        for bond_name in `echo -e "$bond_number" |tr "," "\n"`
        do
        interface_list=`ip a | grep -i " $bond_name "| awk '{print $2}' | awk -F ":" '{print $1}' | tr "\n" "\t"`
        	if [ -z "$interface_list" ]
       		 then
                	echo "FATAL: no interfaces found for $bond_name check if the bondname is correct in the file"
                	exit 2
       		 else
			for interface in `echo -e "$interface_list"| tr " " "\t"`
				do		
		
				echo "INFO: Setting up lldp flag for $interface"
				ethtool --set-priv-flags $interface disable-fw-lldp on
			done
		fi
	done
	echo -e "INFO: Precheck of network lldp">>/tmp/${host_info}_network_status
	sleep 61
	networkctl lldp>>/tmp/${host_info}_network_status

}


function speed_aggregator_test() {	
	local bond_name=$1
	local bond_speed=$2
	echo " in function speed $bond_speed"
	aggregator_count=`cat /proc/net/bonding/$bond_name | grep -i "Aggregator ID" |awk  '{print $1": "$3}'| uniq | wc -l`
#	aggregator_id=`cat /proc/net/bonding/$bond_name | grep -i "Aggregator ID" |awk  '{print $1": "$3}'| uniq |awk  '{print $2}'`
	aggregator_id=`cat /proc/net/bonding/$bond_name | grep -i "Aggregator ID" |awk  '{print $1": "$3}'| uniq`
	interface_speed=`networkctl status $bond_name| grep -i Speed | awk '{print $2}'`
	 echo " in function speed $interface_speed"
		if [[ $aggregator_count -eq 1 && "$interface_speed" == "$bond_speed" ]]
		then
		echo "check 1"
	#	aggregator_id=`cat /proc/net/bonding/$bond_name | grep -i "Aggregator ID" |awk  '{print $1": "$3}'| uniq`
		echo -e "INFO: $bond_name\t$interface_list\t$interface_speed\t$aggregator_id">>/tmp/${host_info}_network_status
		elif [[ $aggregator_count -ne 1 && "$interface_speed" == "$bond_speed" ]] 
		then
		echo "check 2"
		echo -e "ERROR: $bond_name\t$interface_list\t$interface_speed\tAggregator_id_mismatch">>/tmp/${host_info}_network_status
		elif [[ $aggregator_count -eq 1 && "$interface_speed" != "$bond_speed" ]]
		then
			echo "check 3"
	#		aggregator_id=`cat /proc/net/bonding/$bond_name | grep -i "Aggregator ID" |awk  '{print $1": "$3}'| uniq`
			echo -e "ERROR: $bond_name\t$interface_list\tInterface_Speed_mismatch\t$aggregator_id">>/tmp/${host_info}_network_status
		else
			echo "check 4"
			echo -e "ERROR: $bond_name\t$interface_list\tInterface_Speed_mismatch\tAggregator_id_mismatch">>/tmp/${host_info}_network_status
		fi
	}


function interface2_failover_test() {
					local interface=$1		
			     		for gateway in `echo -e "$gateway_details" | tr "," "\n"`
                        				do
                               				 echo $gateway
                            			    	 read gateway_ip interface_name<<<$(echo -e ${gateway} | awk -F ":" '{print $1" "$2}')
                               				 ip a | awk '{print $2}' |grep -i $interface_name
                               				 if [ $? -eq 0 ]
                            				    then
                                				echo "INFO: printing gateway_ip and interface name $gateway_ip $interface_name"
								ping_with_interface_test "$interface"
                                       
                               				 else
                            		    			# echo "Interface $interface_name is not present on this node\nchecking if $gateway_ip is reachable otherwise" >> /tmp/${host_info}_network_status
								ping_without_interface_test "$interface"
        				                 fi
					done
				}


function interface1_failover_test() {
					local interface=$1
                           		for gateway in `echo $gateway_details | tr "," "\n"`
                                		do      
							read gateway_ip interface_name<<<$(echo -e  ${gateway} | awk -F ":" '{print $1" "$2}')
                               				ip a | awk '{print $2}' |grep -i $interface_name
                            				if [ $? -eq 0 ]
                           					then
                               						echo "$gateway_ip $interface_name"
									ping_with_interface_test  "$interface"
                           			         else

                   						   # echo -e "Interface $interface_name is not present on this node,checking if $gateway_ip is reachable otherwise">>/tmp/${host_info}_network_statu
									   ping_without_interface_test  "$interface"
                                							  fi

                       							      done
								      }



function ping_with_interface_test() {
				local interface=$1
                                ping -c60 -q -W1 -I $interface_name $gateway_ip  -M "do" -s $mtu_size
                                        if [ $? -eq 0 ]
                                        then echo  "INFO: system is able to reach the gateway using $interface_name"
                                                echo -e "INFO: $gateway_ip\tReachable\t$interface\t$bond_name\t$mtu_size\t$interface_name" >> /tmp/${host_info}_network_status
                                        else    
						echo "FATAL: system is unable to reach gateway using $interface_name"
                                                echo -e "FATAL: $gateway_ip\tNot_Reachable\t$interface\t$bond_name\t$mtu_size\t$interface_name" >> /tmp/${host_info}_network_status
                                        fi
	
}

function ping_without_interface_test() {
				local interface=$1
                  		ping -c60 -q -W1 $gateway_ip   -M "do" -s $mtu_size
                                       if [ $? -eq 0 ]
                                        then
                                                echo  "INFO: system is able to reach the gateway using $interface_name"
                                                echo -e "INFO: $gateway_ip\tReachable\t$interface\t$bond_name\t$mtu_size" >> /tmp/${host_info}_network_status
                                        else
                                                echo "FATAL: system is unable to reach gateway using $interface_name"
                                                echo -e "FATAL: $gateway_ip\tNot_Reachable\t$interface\t$bond_name\t$mtu_size" >> /tmp/${host_info}_network_status
                                        fi
}


function bond_failover_test() {
	echo " failover $bond_number"
        for bond_name in `echo -e "$bond_number" |tr "," "\n"`
        do
        interface_list=`ip a | grep -i " $bond_name "| awk '{print $2}' | awk -F ":" '{print $1}' | tr "\n" "\t"`
        	if [ -z "$interface_list" ]
        		then
             		   echo "FATAL: no interfaces found for $bond_name check if the bondname is correct in the file"
                	exit 2
    	       else
 		        interface1=`echo $interface_list | awk '{print $1}'`
		        interface2=`echo $interface_list | awk '{print $2}'`
		        interface1_status=`ip link show $interface1 | head -1| awk '{print $11}'`
		        interface2_status=`ip link show $interface2 | head -1| awk '{print $11}'`
	
			speed_aggregator_test "$bond_name" "$bond_speed"
        
			echo -e "INFO: interface list: $interface_list\n$bond_name interface1 name: $interface1\n$bond_name interface2 name: $interface2"
       				 if [ "$interface1_status" == "$interface2_status" ]
  				       then

				         echo "INFO: initiating $bond_name test by bringing down one interface at a time starting with $interface1"
			                ip link set dev $interface1 down
        			        echo "INFO: Interface $interface1 in bond is brough down to test bond failover and connectivity"

					interface2_failover_test  "$interface2"
                			
					echo -e "INFO: Bringing up $interface1\nSetting $interface2 down"

            			      ip link set dev $interface1 up
           				     if [ $? -eq 0 ]
               					 then
							sleep 5
                   				        ip link set dev $interface2 down
                        				if [ $? -eq 0 ]
                       						 then
                               						 sleep 5
									 interface1_failover_test  "$interface1"
               			  			 else
                      						  echo "FATAL: Failed to bring down $interface2 aborting"
                       						   echo -e "FATAL: Partial_Abort_test\t$hostname\t$interface2 down" >>/tmp/${host_info}_network_status
               						 fi
                				 ip link set dev $interface2 up
               					 if [ $? -eq 0 ]
           				         then
                        				echo -e "INFO: brought up $interface2"
          				         else
                  				      echo -e "FATAL: Failed to bring up $interface2 for $host_info" >>/tmp/${host_info}_network_status
             				    	 fi
    			    else
              				  echo "FATAL: Failed to bring up $interface1 aborting"
               				 echo -e  "FATAL: Partial_Abort_test\t$hostname\t$interface1\tdown" >>/tmp/${host_info}_network_status
  			      fi

                else
                  echo -e  "FATAL: One of the interface is already down aborting bonding and gateway test on the $host_info "
                 echo -e "FATAL: Abort NIC failover test for $host_info and $bond_name  \n  $interface1 \t $interface1_status  \t $bond_name \n  $interface2 \t $interface2_status \t $bond_name"  >>/tmp/${host_info}_network_status
		 
        fi

        fi
        done

}

pidof -x  -o $$  $0
	if [ $? -eq 0 ]
		then 
		    echo -e " WARNING: Process bonding_test.sh is already runnning on the node $host_info"
		    exit 2
	else 
		echo -e "INFO: Running the failover test"
#gateway_details=$3
#DNS_TEST=$1
		echo -e  "INFO: printing gateway_details :$gateway_details"
#host_info=$2
#bond_number=$4
		cat /dev/null>  /tmp/${host_info}_network_status
		cat /dev/null>  /tmp/${host_info}_network_status_lastrun
		echo -e "\nHOSTNAME: \t$host_info\t `date '+%Y/%m/%d_%H:%M:%S'`" >> /tmp/${host_info}_network_status
			if [[ "$MGMT_SSH" = "Success" || "$MGMT_SSH" = "NOT_APPLICABLE" ]]
			then
				echo -e "\nINFO:\tMGMT_IP_SSH \t $MGMT_SSH\t$mgmt_addrs"  >> /tmp/${host_info}_network_status
			else 
				echo -e "\nWARNING:\tMGMT_IP_SSH\t$MGMT_SSH\t$mgmt_addrs"  >> /tmp/${host_info}_network_status
			fi
		echo -e "INFO:\tbr-mgmt address\t$mgmt_addrs"  
		echo "INFO: Running Failover Test for host $host_info"

		echo -e "INFO: Performing tests in below sequence\nDEFAUL_GATEWAY: gateway_test\nDNS_TEST: dns_test\nNTP_CHECK: ntp_test\nBOND_List: bond_list\nENABLE_LLDP: enable_lldp\nSPEED_AGGREGATOR_CHECK: bond_failover_test\nBOND_FAILOVER_TEST: bond_failover_test"


gateway_test
dns_test
ntp_test
bond_list
enable_lldp
bond_failover_test


	sleep 70
        echo -e "\nPost bond failover lldp check \n" >>/tmp/${host_info}_network_status
	networkctl lldp >>/tmp/${host_info}_network_status
        
	mv /tmp/${host_info}_network_status /tmp/${host_info}_network_status_lastrun
fi
