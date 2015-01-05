#!/bin/bash


##############################################################
#
# This script pulls info from an ITOP cmdb to generate 
# a yaml hosts list to be used as a Dynamic Inventory Source 
# for ansible commands 
# 
# Parameters : Passed as enviroment variable, it could be one of the following
# 
#  OQL = Sentence in OQL l, 
#      eg export OQL="SELECT Server WHERE status = 'stock'"
#
#  OQL = Link to an audit rule, 
#      eg OQL="https://demo.combodo.com/simple/pages/audit.php?operation=csv&category=3&rule=1&c[menu]=Audit"
#
#  OQL = Name of an existing audit rule, to get objects from, 
#      eg OQL="Server in Stock"
#  FIELD = (optional) name of the field to be used as hostname
#
#  You can also set variables to ansible, eg :
#  export VAR="\"ansible_ssh_pass\" : \"mypassword\" "
#  so you can set ssh password to be used.
# 
# Usage example :
#   
# Do a ping against all VM belonging to hypervisor prod-epg-esxi-04.hi.inet 
# export OQL="SELECT VirtualMachine WHERE virtualhost_name = 'prod-epg-esxi-04.hi.inet' " ; ansible all -i FromITOPtoAnsible.sh -m shell -m "ping"
#
#
############################################################## 

###########################################################
#
# Configurable parameters
#
############################################################

# Stored in .credentials

###########################################################
# End of configurable parameters
#
############################################################
# Other non configurable parameters
SERVER=
PROTOCOL=http
TEMP_CSV_FILE=out.csv
MODE_FLAG=description
CATEGORY=
RULE=
CURL_OPTIONS='-s '
WGET_OPTIONS='-q '
# End of non configurable parameters


# This functions is not mine. Credits to 
# cdown / gist:1163649 https://gist.github.com/cdown/1163649
urlencode( )
{
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
  # Load From Credentials 
  MY_USER=${ITOP_USER}
  MY_PASS=${ITOP_PASS}


  # If we use https, change options accordingly
  [ ` echo $HTTPS | grep -i Y | wc -l ` -eq 1 ] && PROTOCOL=https && CURL_OPTIONS='-s -k ' && WGET_OPTIONS='-q --no-check-certificate'

  [[ -z "$FIELD" ]] && FIELD=name
  ENCODED_STRING=`urlencode "$OQL"`
  SERVER="${PROTOCOL}://${ITOP_SERVER}/${INSTALLATION_DIRECTORY}/webservices/export.php?c%5Bmenu%5D=ExportMenu"

  URL_STRING="&expression="${ENCODED_STRING}
  LAST_URL_OPTIONS="&format=csv&login_mode=basic&fields=${FIELD}"
}

GetWorkingPath( )
{
  # GetWorking Path
  FULL_SCRIPT_PATH=`readlink -f $0`
  WORKING_PATH=`dirname $FULL_SCRIPT_PATH`
}

PreWork( )
{
  GetWorkingPath 
  source $PWD/.credentials
  MY_USER=${ITOP_USER}
  MY_PASS=${ITOP_PASS}

  SetVariables
  # If we detect OQL variable is a link from an audit category, change the mode
  [ ` echo $OQL | grep SELECT | wc -l ` -eq 1 ] && MODE_FLAG='select' 
  [ ` echo $OQL | grep -i http | grep -i category | grep -i rule | wc -l ` -eq 1 ] && MODE_FLAG='audit' 
  [ ` echo $OQL | grep -i http | grep -i filter  | wc -l`  -eq 1 ] && MODE_FLAG='filter'
}

QueryITOP( )
{
  wget ${WGET_OPTIONS} -O $TEMP_CSV_FILE --http-user=$MY_USER --http-password=$MY_PASS  ${SERVER}${URL_STRING}${LAST_URL_OPTIONS}
}

QueryITOPAudit( )
{
 curl ${CURL_OPTIONS} -d "auth_pwd=$MY_PASS&auth_user=$MY_USER&loginop=login" --dump-header headers "${PROTOCOL}://${ITOP_SERVER}/${INSTALLATION_DIRECTORY}/pages/audit.php?operation=csv&category=$CATEGORY&rule=$RULE&filename=audit.csv&c%5Borg_id%5D=$ORGANIZATION" > $TEMP_CSV_FILE

}

QueryITOPFilter( )
{
 curl ${CURL_OPTIONS} -d "auth_pwd=$MY_PASS&auth_user=$MY_USER&loginop=login" --dump-header headers "${PROTOCOL}://${ITOP_SERVER}/${INSTALLATION_DIRECTORY}/pages/UI.php?operation=search&filter=${FILTER}&format=csv" > $TEMP_CSV_FILE
RIGHT_PART=`grep -o  expression.*\"\>Dow  $TEMP_CSV_FILE |  cut -d\" -f1`

 curl ${CURL_OPTIONS} -d "auth_pwd=$MY_PASS&auth_user=$MY_USER&loginop=login" --dump-header headers "${PROTOCOL}://${ITOP_SERVER}/${INSTALLATION_DIRECTORY}/webservices/export.php?${RIGHT_PART}"  > $TEMP_CSV_FILE

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
#	echo "{ \"hosts\" : [ ${HOST_LIST} ] }"
if [ ${#VAR} -gt 0 ]
then
  echo "{ \"hosts\" : [ ${HOST_LIST} ] ,"

  echo '"_meta" : {'
  echo '  "hostvars" : {'
echo ${HOST_LIST} | sed -e "s/\" /\" : \{ ${VAR} \} /g" |  sed -e "s/\"$/\" : \{ ${VAR} \} /g"
  echo '      }'
  echo '   }'
  echo '}'
else
    echo "{ \"hosts\" : [ ${HOST_LIST} ] }"
fi


}

PostWork( )
{
	rm -f $TEMP_CSV_FILE.tmp $TEMP_CSV_FILE headers 2>/dev/null 
}

ExtractValuesAudit( )
{
	CATEGORY=`echo $OQL | egrep -o --colour category=[0-9].  | cut -d\= -f2`
	RULE=`echo $OQL | egrep -o --colour rule=[0-9]*  | cut -d\= -f2`
  ORGANIZATION=`echo $OQL | egrep -o --colour 'c\[org_id\]='[0-9]*  | cut -d\= -f2`
  
}


ExtractValuesFilter( )
{
  FILTER=`echo $OQL |  egrep -o --colour  'filter='[a-zA-Z0-9\%]*  | cut -d\= -f2`
  ORGANIZATION=`echo $OQL | egrep -o --colour 'c\[org_id\]='[0-9]*  | cut -d\= -f2`

}

ExtractValuesDescription( )
{
   # Resolve the audit category (Name of the audit category must by univoque)
   FILE_TMP=/tmp/kk-tmp-$$

   curl ${CURL_OPTIONS} -d "auth_pwd=$MY_PASS&auth_user=$MY_USER&loginop=login" --dump-header headers "${PROTOCOL}://${ITOP_SERVER}/${INSTALLATION_DIRECTORY}/pages/audit.php?c%5Borg_id%5D=999&c%5Bmenu%5D=Audit" | sed -e 's/\&aacute;/á/g' -e 's/\&eacute;/é/g' -e 's/\&iacute;/í/g' -e 's/\&oacute;/ó/g' -e 's/\&uacute;/ú/g' -e 's/\&ntilde;/ñ/g' -e 's/\&Aacute;/Á/g' -e 's/\&Eacute;/É/g' -e 's/\&Iacute;/Í/g' -e 's/\&Oacute;/Ó/g' -e 's/\&Uacute;/Ú/g' -e 's/\&Ntilde;/Ñ/g'  > $FILE_TMP
   LAST_URL=`grep -i "$OQL" $FILE_TMP  | egrep -o audit.* | cut -d\" -f1`
   OQL="${PROTOCOL}://${ITOP_SERVER}/${INSTALLATION_DIRECTORY}/pages/$LAST_URL"
   
   rm -f $FILE_TMP


}
#
# Query the OQL looking for audit category or OQL SELECT
#, urlencode it, send it to the itop server
# and format its response
#
ItopDialog( )
{
  case $MODE_FLAG in
  
   ( description )
      ExtractValuesDescription
      ExtractValuesAudit
      QueryITOPAudit
      BuildYAMLOutputAudit
    ;;

   ( select )
      # Query ITOP's php export webservice
      QueryITOP

      # Format itop response
      BuildYAMLOutput
      ;; 
  ( audit )  #

      ExtractValuesAudit
      QueryITOPAudit
      BuildYAMLOutputAudit
      ;;

  ( filter )
      ExtractValuesFilter
      QueryITOPFilter
      BuildYAMLOutputAudit
     ;;
esac
 

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

