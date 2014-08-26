#!/bin/bash

##############################################################
#
# This script pulls info from an ITOP cmdb to generate 
# a yaml hosts list to be used as a Dynamic Inventory Source 
# for ansible commands 
# 
# Parameters : Passed as enviroment variable 
#  OQL = Sentence in OQL 
#  FIELD = (optional) name of the field to be used as hostname 
# 
# Usage example :
#   
# Do a ping against all VM belonging to hypervisor prod-epg-esxi-04.hi.inet 
# export OQL="SELECT VirtualMachine WHERE virtualhost_name = 'prod-epg-esxi-04.hi.inet' " ; ansible all -i FromITOPtoAnsible.sh -m shell -m "ping"
#
############################################################## 

# Parameters: Change this according to your itop credentials 
MY_USER=replace_for_your_itop_user
MY_PASS=replace_for_your_itop_password
ITOP_SERVER=replace_for_your_itop_server
# End of configurable parameters

# Other parameters
SERVER="http://$ITOP_SERVER/itop-itsm/webservices/export.php?c%5Bmenu%5D=ExportMenu"
TEMP_CSV_FILE=out.csv
AUDIT_FLAG=0
CATEGORY=
RULE=



# This functions is not mine. Credits to 
# cdown / gist:1163649 https://gist.github.com/cdown/1163649
urlencode() {
    # urlencode <string>
 
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c"
        esac
    done
}
 
# Set variables
# If env variable FIELD is unset, set it to "name"
SetVariables( )
{
	[[ -z "$FIELD" ]] && FIELD=name
	ENCODED_STRING=`urlencode "$OQL"`
	URL_STRING="&expression="${ENCODED_STRING}
	LAST_URL_OPTIONS="&format=csv&login_mode=basic&fields=${FIELD}"
}

PreWork( )
{
	SetVariables
  # If we detect OQL variable is a link from an audit category, change the mode
  AUDIT_FLAG=` echo $OQL | grep -i http | grep -i category | grep -i rule | wc -l `

}

QueryITOP( )
{
	wget -q -O $TEMP_CSV_FILE --http-user=$MY_USER --http-password=$MY_PASS  ${SERVER}${URL_STRING}${LAST_URL_OPTIONS}
}

QueryITOPAudit( )
{
 curl -s -d "auth_pwd=$MY_PASS&auth_user=$MY_USER&loginop=login" --dump-header headers "http://${ITOP_SERVER}/itop-itsm/pages/audit.php?operation=csv&category=$CATEGORY&rule=$RULE&filename=audit.csv&c%5Borg_id%5D=$ORGANIZATION" > $TEMP_CSV_FILE
}

BuildYAMLOutputAudit( )
{
	grep -i  '^\"'   $TEMP_CSV_FILE > $TEMP_CSV_FILE.tmp
	mv -f $TEMP_CSV_FILE.tmp $TEMP_CSV_FILE
  HOST_LIST=` cat $TEMP_CSV_FILE |  cut -d\, -f1 |  sed ':a;N;$!ba;s/\n/ , /g'`
}


BuildYAMLOutput( )
{
	grep -v "\[" $TEMP_CSV_FILE > $TEMP_CSV_FILE.tmp
	mv -f $TEMP_CSV_FILE.tmp $TEMP_CSV_FILE
	HOST_LIST=` cat $TEMP_CSV_FILE |  grep \" |  sed ':a;N;$!ba;s/\n/ , /g'` 
}

AnsibleReturnHostsList( )
{
	echo "{ \"hosts\" : [ ${HOST_LIST} ] }"
}

PostWork( )
{
	rm -f $TEMP_CSV_FILE.tmp $TEMP_CSV_FILE 2>/dev/null 
}

ExtractValuesAudit( )
{
	CATEGORY=`echo $OQL | egrep -o --colour category=[0-9].  | cut -d\= -f2`
	RULE=`echo $OQL | egrep -o --colour rule=[0-9]*  | cut -d\= -f2`
  ORGANIZATION=`echo $OQL | egrep -o --colour 'c\[org_id\]='[0-9]*  | cut -d\= -f2`
  
}

#
# Query the OQL looking for audit category or OQL SELECT
#, urlencode it, send it to the itop server
# and format its response
#
ItopDialog( )
{
if [ $AUDIT_FLAG -eq 0 ]
then

  # Query ITOP's php export webservice
  QueryITOP

  # Format itop response
  BuildYAMLOutput

else

  ExtractValuesAudit
  QueryITOPAudit
  BuildYAMLOutputAudit

fi

}


############################
# Main
############################

# Prepare URL
PreWork

# Itop Dialoge
ItopDialog

# Return response to Ansible
AnsibleReturnHostsList


# Delete temp files
PostWork

exit 0

