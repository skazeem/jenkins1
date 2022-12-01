#!/bin/bash 

date=`date '+%Y/%m/%d %H:%M:%S'`
cat /dev/null &> /tmp/deployed_systems_network_status
cat /dev/null &> /tmp/deployed_systems_network_status_failure_lastrun
echo -e "\t\t $date " > /tmp/deployed_systems_network_status
for filename in `ls -lrt /tmp/networking_test_output/| awk '{print $9}'`
        do

                cat /tmp/networking_test_output/$filename >> /tmp/deployed_systems_network_status
                fail_check=`cat /tmp/networking_test_output/$filename| grep -i "Error\|FATAL\|WARNING"  | wc -l`
		if [ $fail_check -gt 0 ]
		then
			echo -e "\n`grep -i "hostname\|ERROR\|WARNING\|FATAL"  /tmp/networking_test_output/$filename`" >> /tmp/deployed_systems_network_status_failure_lastrun
		fi
			

        done
  echo -e "INFO: POST OS deployment check on the below nodes is completed \n`cat /tmp/post_check_server_list_lastrun| grep -i deployed`\n\n"
#  if [ `cat /tmp/deploy_server_fail_lastrun | wc -l` -gt 0 ]
#  then
#  echo -e "WARNING: Check OS deployment on the below nodes manually \n `cat /tmp/deploy_server_fail_lastrun`"
#  fi
echo -e "\n\n================================================================================================================\n\nINFO: showing network check report for above listed hosts\n\n================================================================================================================\n\n"
cat /tmp/deployed_systems_network_status
#echo "FATAL: showing network check report for above listed hosts with errors"
#cat /tmp/deployed_systems_network_status | grep -v INFO | grep -i "hostname\|fatal\|warning"
echo -e "Moving the files as backup /tmp/deployed_systems_network_status_lastrun for this run"
mv /tmp/deployed_systems_network_status /tmp/deployed_systems_network_status_lastrun


 

fail_count=`cat /tmp/deployed_systems_network_status_failure_lastrun| wc -l`

if [ $fail_count -eq 0 ]
then
	echo -e "\n\nThere are no issue in post config checks"
else
#	grep -i "hostname\|ERROR\|WARNING\|FATAL" /tmp/deployed_systems_network_status_lastrun > /tmp/deployed_systems__network_status_failure_lastrun
	echo -e "\n\n================================================================================================================\n\nWARNING: There are some issues observed  in the post configurations checks for below hosts\n\n================================================================================================================\n\n`cat /tmp/deployed_systems_network_status_failure_lastrun`"
	exit 2
fi
#cd /tmp
#rm -rf /tmp/networking_test_output_old/*
#mv networking_test_output/ networking_test_output_old/


