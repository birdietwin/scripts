#! /bin/bash

set DEFSTATE=$*

if [ "X$DEFSTATE" == "X" ] 
then
	DEFSTATE=running
fi

aws ec2 describe-instances --filters "Name=instance-state-name,Values=${DEFSTATE}" |  jq '.Reservations | .[] | .Instances | .[] | .InstanceId'