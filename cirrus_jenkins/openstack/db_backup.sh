#!/bin/bash
  
DAYS=7
mkdir -p /dbbackup
find /dbbackup/* -mtime +$DAYS -exec rm -f {} \;

NOW="$(date +"%d-%m-%Y_%s")"

db_file_name="backup_$NOW.sql"

mysqldump --user=root --password=admin --lock-tables --all-databases > /dbbackup/$db_file_name

if [ -e "/dbbackup/$db_file_name" ];
then
        echo "backup completed successfully"

else
echo "backup failed"

fi

echo "backup size is: ` du -sh /dbbackup/$db_file_name | awk '{print $1}'`"
