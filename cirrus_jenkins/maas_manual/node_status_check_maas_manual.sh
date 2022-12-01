#!/bin/bash -xv
maas_admin=$1
#server_list=$6
maas_server_ip=$2
#server_count=2
server_list=`echo -e "$3" |tr " " "\n"`

echo -e "$server_list"
echo -e "$server_list" | wc -l
