disks=`lsblk -f -n -p -s -i | grep "^/dev/sd" | awk '$2 =="" {print $1}'`
nvme_disk=`lsblk -f -n -p -s -i | grep "^/dev/nvme" | awk '$2 =="" {print $1}'`
nvme_disks=`echo $nvme_disk | awk '{for (i=1; i<NF; i++) printf $i ","; print $NF}'`
hdd_list=`echo $disks | awk '{for (i=1; i<NF; i++) printf $i ","; print $NF}'`
echo "$nvme_disks,$hdd_list"
