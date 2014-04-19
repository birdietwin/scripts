#! /bin/bash
# aws-instance-state.sh     LIST AWS INSTANCES - USEFUL STATUS DETAILS IN TABLE, JSON OR TEXT FORMAT
# 							TOM KIMES
#							4/4/2014

usage() {
	echo
	echo "Usage: aws-instance-status.sh  -s <r|s|t>  -o >t|j|x   -t <d|l> -d  [ instance-id [ instance-id2 ] ... [instance-idn] ]"
    echo "       -s      Run State    r|s|t|b|h|p      r=running, s=stopping|stopped, t=terminated, b=rebooting, h=shutting, p=pending, "
    echo "       -o      Output       t|j|x      t=table, j=json, x=text"
	echo "       -l      List Output  d|l        d=dictionary table, l=list table"
	echo "       -t      Tag Option   [<key>]    provide tag key for tag colume <default is 'name'>."
    echo "       -d      enable debug (more verbose) mode"
	echo "       The default is to view all instances in all run states in a dictionary table: -ot -tl"
}

DEBUG=

TAGCMD=$(which aws-tag-id.sh)
if [ ! "$TAGCMD" ]
then
	echo "ERROR: Script aws-tag-id.sh was not found in path.  Cannot continue."
	usage
	exit 1
fi

while getopts 's:o:l:t:d?' option
do
  case "$option" in
  s)    status_filter=$OPTARG
        ;;
  o)    output=$OPTARG
        ;;
  l)    list_output=$OPTARG
        ;;
  t)    tag_key=$OPTARG
		;;
  d)    DEBUG=debug
        ;;
  ?)    usage
	  	exit 0
        ;;
  esac
done

shift "$(( OPTIND - 1 ))"

INSTANCE="$@"

[ "$DEBUG" ] && echo "Debug:  INSTANCE: ${INSTANCE:-all}"

case "$status_filter" in
	s)  STATE=stop
		;;
	r)	STATE=running
		;;
	t)  STATE=terminated
		;;
	b)  STATE=rebooting
		;;
	h)  STATE=shutting
		;;
	p)  STATE=pending
		;;
	'') STATE=  #DEFAULT IS ALL STATES
	    ;;
	*)  echo "ERROR:  -s $status_filter   is not a valid state"
	    usage
	    exit 1
		;;
esac

[ "$DEBUG" ] && echo "Debug:     STATE: ${STATE:-all}"


case "$output" in
	t)  OUTPUT=table
		;;
	j)  OUTPUT=json
		;;
	x)  OUTPUT=text
		;;
   '')  OUTPUT=table  # DEFAULT IS TABLE
		;;
    *)  echo "ERROR:  -o $output   is not a valid output option"
	    usage
	    exit 1
		;;
esac

[ "$DEBUG" ] && echo "Debug:    OUTPUT: $OUTPUT"

case "$list_output" in
	d)  FORMAT=dictionary
		;;
	l)	FORMAT=list
		;;
   '')  
	    FORMAT=dictionary  #DEFAULT IS DICTIONARY
 		;;
	*)  echo "ERROR:  -l $list_output   is not a valid format type"
	    usage
	    exit 1
		;;
		
esac

[ "$DEBUG" ] && echo "Debug:    FORMAT: $FORMAT"

if [ "X$tag_key" == "X" ]
then
  tag_key="Name"
fi

[ "$DEBUG" ] && echo "Debug:   TAG_KEY: $tag_key"

# FIELDS TO INCLUDE IN QUERY
# STRUCTURE IS <LIST LABEL>:FIELD.ELEMENT
F00="_00_id:Instances[0].InstanceId"
#F01="01_name:Instances[0].Tags[?Key==\`Name\`].Value[*]"  # THIS INNER JOIN CAUSES THE FORMATTER TO LABEL EACH ROW :( 
F01="_01_name:Instances[0].Tags[0].Value"
F02="_02_Type:Instances[0].InstanceType"
F03="_03_key:Instances[0].KeyName"
F04="_04_priv_ip:Instances[0].PrivateIpAddress"
F05="_05_pub_ip:Instances[0].PublicIpAddress"
F06="_06_stat:Instances[0].State.Name"
F07="_07_secur_grp:Instances[0].SecurityGroups[0].GroupName"
F08="_08_launch_time:Instances[0].LaunchTime"

# LIST MODE - REMOVE COLUMN LABEL AND COLON
L00="$(echo $F00|cut -d: -f2-)"
L01="$(echo $F01|cut -d: -f2-)"
L02="$(echo $F02|cut -d: -f2-)"
L03="$(echo $F03|cut -d: -f2-)"
L04="$(echo $F04|cut -d: -f2-)"
L05="$(echo $F05|cut -d: -f2-)"
L06="$(echo $F06|cut -d: -f2-)"
L07="$(echo $F07|cut -d: -f2-)"
L08="$(echo $F08|cut -d: -f2-)"

#COPY TAG WITH NAME KEY TO ~ID TO SUPPORT F01,L01  (OTHERWISE A RANDOM KEY VALUE APPEARS)
$TAGCMD -t "~ID" -c $INSTANCE

if [ "X$FORMAT" == "Xdictionary" ] # IF DICTIONARY FORMAT
then
	# DICTIONARY VIEW: QUERY INSTANCES, FILTER ON RUN STATE, LIST SPECIFIC FIELD AND OUTPUT IN A TABLE
	# SEE http://docs.aws.amazon.com/cli/latest/userguide/controlling-output.html
	if [ "X$debug" != "X" ]
	then
		echo "F00 $F00"
		echo "F01 $F01"
		echo "F02 $F02"
		echo "F03 $F03"
		echo "F04 $F04"
		echo "F05 $F05"
		echo "F06 $F06"
		echo "F07 $F07"
		echo "F08 $F08"
	fi
	aws ec2 describe-instances  --no-paginate \
		--filters "Name=instance-state-name,Values=${STATE:-*}*" \
		--output $OUTPUT  \
		--query "Reservations[*].{${F00},${F01},${F02},${F03},${F04},${F05},${F06},${F07},${F08}}" --instance-id $INSTANCE
else	# LIST FORMAT
	# LIST VIEW: QUERY INSTANCES, FILTER ON RUN STATE, LIST SPECIFIC FIELD AND OUTPUT IN A TABLE
	if [ "X$debug" != "X" ]
	then
		echo "L00 $L00"
		echo "L01 $L01"
		echo "L02 $L02"
		echo "L03 $L03"
		echo "L04 $L04"
		echo "L05 $L05"
		echo "L06 $L06"
		echo "L07 $L07"
		echo "L08 $L08"
	fi
	aws ec2 describe-instances --no-paginate \
		--filters "Name=instance-state-name,Values=${STATE:-*}*" \
		--output $OUTPUT  \
		--query "Reservations[*].[${L00},${L01},${L02},${L03},${L04},${L05},${L06},${L07},${L08}]" --instance-id $INSTANCE
fi    

#REMOVE TAG WITH NAME KEY TO ~ID TO SUPPORT F01,L01
$TAGCMD -t "~ID" -r $INSTANCE
 
exit 0
