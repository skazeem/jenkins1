#!/bin/bash
cd /root/
cat /dev/null &> /root/nohup.out
nohup /root/bonding_test.sh > /dev/null 2>&1 &
exit
