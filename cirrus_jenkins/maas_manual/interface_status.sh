sudo host_info=`hostname` ; sudo ip a| grep -i "No-carrier" | awk  '{ print $2" "$9}' > /tmp/${host_info}_network_interfaces_status
