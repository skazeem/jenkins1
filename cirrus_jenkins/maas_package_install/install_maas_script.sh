#!/bin/bash -xv
version=$1
maas_admin=$2
maas_admin_email=$3
maas_password=$4
ntp_server=$5
http_proxy=$6
dns_server=$7
maas_server_ip=$8

maas_dhcp_subnet=$9
dhcp_range_start_ip="${10}"
dhcp_range_end_ip="${11}"
create_passwordless_ssh_key="${12}"
maas_server_admin="${13}"
os_list="${14}"

if [  -z $maas_password ]
	then
	echo "Maas password value is set to null"

	exit 2

else
echo "Add MAAS repository"


sudo add-apt-repository -yu ppa:maas/$version
check=`dpkg -l | grep -i maas| wc -l`
if [ $check -lt 1 ]
 then
        echo "Installing mass package"
        sudo apt install maas -y
#       sudo apt install maas-* -y
                if [ $? -eq 0 ]; then
                        echo "creating Maas Admin"
                        sudo maas createadmin --username=$maas_admin --email=$maas_admin_email --password=$maas_password
                        echo "creating MAAS API key"
                         api_key="`sudo maas apikey --username $maas_admin`"
                        echo" login into the MAAS url using the $api_key"
                         sudo maas login $maas_admin http://$maas_server_ip:5240/MAAS $api_key
                        echo "Set up NTP interface"
                         sudo maas $maas_admin maas set-config name=ntp_external_only value=true
			 for ntp_server1 in `echo -e "$ntp_server" |tr "," "\n"`
			 do
                         sudo maas $maas_admin maas set-config name=ntp_servers value=$ntp_server1
		 	 done
                        echo "Set up Proxy server"
                         sudo maas $maas_admin maas set-config name=enable_http_proxy value=true
                         sudo maas $maas_admin maas set-config name=http_proxy value=$http_proxy
                        echo "Set up the DNS server"
			 for dns_server1 in `echo -e "$dns_server" |tr "," "\n"`
			 do
                         sudo  maas $maas_admin maas set-config name=upstream_dns value=$dns_server1
		 	 done
                        echo " Disabling network discovery"
                         sudo maas $maas_admin maas set-config name=network_discovery value="disabled"
                        echo " Add the boot images"
			for os_info in `echo -e "$os_list"| tr " " "\n"`
			do
				os_name=`echo "$os_info"|awk -F "," '{print $1}'`
				os_codename=`echo "$os_info"|awk -F "," '{print $2}'`
                         sudo maas $maas_admin boot-source-selections create 1  os="ubuntu" release="focal" arches="amd64" subarches="*" labels="*"
			done
			 sudo maas $maas_admin boot-resources import

                        echo " Enable the DHCP"
                         sudo maas $maas_admin ipranges create type=dynamic start_ip="$dhcp_range_start_ip"  end_ip="$dhcp_range_end_ip" subnets="$maas_dhcp_subnet"
                         vlan_id=`sudo  maas $maas_admin subnets read |   jq -r '.[]  | .vlan.vid'`
                         primary_rack=`sudo maas $maas_admin rack-controllers read |  jq -r '.[]  | .system_id'`
                         sudo maas $maas_admin vlan update $vlan_id untagged dhcp_on=True primary_rack=$primary_rack
                        echo "Adding ssh keys to MAAS for user: $maas_server_admin"
                        if [ $create_passwordless_ssh_key = "Yes" ]
                                then
                                echo -e "\n\n\n" | ssh-keygen -t rsa
                                path=`grep -i $maas_server_admin /etc/passwd | awk -F ":" '{print $6}'`
                                key_file=`echo $path/.ssh/id_rsa.pub`
				if [ -f $key_file ]
				then
					echo " ssh key file is  created"

                                sudo maas $maas_admin sshkeys create key="$(sudo cat $key_file)"
                                echo "created a new ssh public key as $key_file and added it to MAAS config"
				else
				       echo " key is not created exiting the script"
			       	       exit 2
				fi
                         else
                                echo "Adding public key already present"
                                path=`grep -i $maas_server_admin /etc/passwd | awk -F ":" '{print $6}'`
                                key_file=`echo $path/.ssh/id_rsa.pub`
				if [ -f $key_file ]
				then
                                   sudo maas $maas_admin sshkeys create key="$(sudo cat $key_file)"
				   echo " Adding the existing key"
				else
				   echo " No key file file $key_file present on the maas server"
				   exit 2
				fi
                        fi
                else
                echo "MAAS iinstallation failed"
                fi
else
echo "MAAS is already installed"
exit 1
fi

fi
