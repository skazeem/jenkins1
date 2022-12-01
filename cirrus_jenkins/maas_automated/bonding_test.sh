#!/bin/bash -xv 
gateway_details=$3
DNS=$1
echo -e  "printing gateway_details :$gateway_details"
host_info=$2
bond_number=$4
cat /dev/null>  /tmp/${host_info}_network_status
echo -e "\t$host_info" >> /tmp/${host_info}_network_status

	nslookup $DNS
	if [ $? -eq 0 ]
	then

 	echo -e "$host_info\t$DNS\tDNS_Reachable" >>/tmp/${host_info}_network_status

	else
 	echo -e "$host_info\t$DNS\tDNS_NOT_Reachable ">>/tmp/${host_info}_network_status

	fi
	for bond_name in `echo -e "$bond_number" |tr "," "\n"`
	do	
	interface_list=`ip a | grep -i " $bond_name "| awk '{print $2}' | awk -F ":" '{print $1}' | tr "\n" "\t"`
	if [ -z "$interface_list" ]
	then 
		echo " no interfaces found for $bond_name check if the bondname is correct in the file"
		exit 2
	else
	interface1=`echo $interface_list | awk '{print $1}'`
	interface2=`echo $interface_list | awk '{print $2}'`
	interface1_status=`ip link show $interface1 | head -1| awk '{print $11}'`
	interface2_status=`ip link show $interface2 | head -1| awk '{print $11}'`
	echo -e "interface list: $interface_list\n$bond_name interface1 name: $interface1\n$bond_name interface2 name: $interface2"
	if [ "$interface1_status" == "$interface2_status" ]
	 then
	 
	 echo "initiating $bond_name test by bringing down one interface at a time starting with $interface1"
 		ip link set dev $interface1 down
 		echo " Interface $interface1 in bond is brough down to test bond failover and connectivity"
		sleep 8
 		for gateway in `echo -e "$gateway_details" | tr " " "\n"`
			do
				echo $gateway
				read gateway_ip interface_name<<<$(echo -e ${gateway} | awk -F "," '{print $1" "$2}')
				echo "printing gateway_ip and interface name $gateway_ip $interface_name"
				ping -c2 -q -W1 -I $interface_name $gateway_ip
					if [ $? -eq 0 ]
 			 		then echo  "system is able to reach the gateway using $interface_name"
 						echo -e "$gateway_ip\t$interface_name\t$interface2\t$bond_name\tReachable" >> /tmp/${host_info}_network_status
					else 	echo " system is unable to reach gateway using $interface_name"
		  	 			echo -e "$gateway_ip\t$interface_name\t$interface2\t$bond_name\tNot_Reachable" >> /tmp/${host_info}_network_status
					fi
 		done	
   		echo -e "Bringing up $interface1\nSetting $interface2 down"
	 	ip link set dev $interface1 up
 		if [ $? -eq 0 ]
  		then
			sleep 8
   			echo -e "Bringing up $interface1\nSetting $interface2 down"
 			ip link set dev $interface2 down
 			if [ $? -eq 0 ]
			then
				sleep 8
				for gateway in `echo $gateway_details | tr " " "\n"`
				do	read gateway_ip interface_name<<<$(echo -e  ${gateway} | awk -F "," '{print $1" "$2}')
				echo "$gateway_ip $interface_name"
				ping -c2 -q -W1 -I $interface_name $gateway_ip
					if [ $? -eq 0 ]
 			 		then 	echo  "system is able to reach the gateway using $interface_name"
						echo -e "$gateway_ip\t$interface_name\t$interface1\t$bond_name\tReachable" >>/tmp/${host_info}_network_status
		 			else    echo " system is unable to reach gateway using interface"
		  	 			echo -e "$gateway_ip\t$interface_name\t$interface1\t$bond_name\tNot_Reachable" >>/tmp/${host_info}_network_status
 					fi
 			done
		else
			echo "Failed to bring down $interface2 aborting"
			echo -e "Partial_Abort_test\t$hostname\t$interface2 down" >>/tmp/${host_info}_network_status
		fi
		 ip link set dev $interface2 up
		if [ $? -eq 0 ]
		then
			echo -e " brought up $interface2"
		else
			echo -e "Failed to bring up $interface2 for $host_info" >>/tmp/${host_info}_network_status
		fi
 	else
 		echo "Failed to bring up $interface1 aborting"
 		echo -e  "Partial_Abort_test\t$hostname\t$interface1\tdown" >>/tmp/${host_info}_network_status
 	fi
	
		else
		  echo " One of the interface is already down aborting bonding and gateway test on the $host_info"
 		 echo " Abort bond failover test for $host_info" >>/tmp/${host_info}_network_status
	fi
	
	mv /tmp/${host_info}_network_status /tmp/${host_info}_network_status_lastrun
	fi
	done
