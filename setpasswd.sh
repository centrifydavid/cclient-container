#!/bin/bash
export PASS=`openssl rand -base64 16`
echo $PASS | passwd --stdin root
echo $PASS | /usr/sbin/csetaccount --stdin -m true -p \"role:DevOps:Edit,Checkout,View,Login\" root 
