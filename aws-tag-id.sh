#! /bin/bash
# 
# AWS-TAG-ID.SH
# WRITTEN BY : TOM KIMES
# DATE: APRIL 19 2014
# PURPOSE: TO LIST, COPY OR REMOVE THE NAME TAG
#          COPY OPTION COPIES TAG TO A LOW COLLATING
#             VALUE KEY TO FORCE NAME KEY IN INSTANCE LIST
#          SINCE THIS ROUTINE CONSUMES A RESOURCE KEY, 
#             IT WILL NOT SCALE TO SUPPORT CONCURRENT OPERATIONS
#          DO NOT USE IN PRODUCTION PROCESSES!  YOU HAVE BEEN WARNED!!!!
########################################################################

usage() {
	echo
	echo "Usage: aws-tag.sh  -c  -r   -t <tag-key> -d  [ instance-id,[ instance-id2 ], ... [instance-idn] ]"
    echo "       -c      Create tag"
    echo "       -r      Remove tag"
    echo "       -l      List tag"
	echo "       -t      Tag Key   [<key>]    provide temporary tag key"
    echo "       -d      enable debug (more verbose) mode"
	echo "       -?      Usage (this message)"
	echo "               Instance-id list seperate with commas (wildcard ok) or space."
}

DEBUG=
create_flag=
remove_flag=
list_flag=

while getopts 't:crld?' option
do
  case "$option" in
  c)    create_flag=1
        ;;
  r)    remove_flag=1
        ;;
  l)    list_flag=1
	          ;;
  t)    tag_key=$OPTARG
		;;
  d)    DEBUG=1
        ;;
  ?)    usage
	  	exit 0
        ;;
  esac
done

shift "$(( OPTIND - 1 ))"

INSTANCELIST="$@"

#COMMA SEPERATE INSTANCE-ID LIST.  SPACES ARE REPLACED BY COMMAS.  
[ "$INSTANCELIST" ] && INSTANCE=$(echo $INSTANCELIST | sed 's/[ 	*][ 	*]/ /g' | sed 's/ /,/g')

[ $DEBUG ] && echo "Instance: $INSTANCE"

if [ ! $tag_key ]
	then
	if [ $create_flag ] || [ $remove_flag ]
		then
		echo "ERROR: A Tag Key must be provided to create or remove tags"
		usage
		exit 1
	fi
fi

[ $DEBUG ] && echo "Tag Key: $tag_key"

while read RESOURCE NAMETAG
do
  [ $list_flag ] &&	echo $RESOURCE "|" $NAMETAG
  [ $create_flag ] && aws ec2 create-tags --resources "$RESOURCE" --tags Key=$tag_key,Value=$NAMETAG >/dev/null && [ $list_flag ] && echo "$RESOURCE tag $tag_key created"
  [ $remove_flag ] && aws ec2 delete-tags --resources "$RESOURCE" --tags Key=$tag_key                >/dev/null && [ $list_flag ] && echo "$RESOURCE tag $tag_key removed"
done < <(aws ec2 describe-tags --output text --filters "Name=resource-id,Values=$INSTANCE" "Name=key,Values=Name" --query "Tags[*].[ResourceId,Value]" --no-paginate)

