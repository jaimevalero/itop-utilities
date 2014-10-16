#!/bin/bash

##############################################################
#
# This script pulls info from an mysql to generate 
# a yaml hosts list to be used as a Dynamic Inventory Source 
# for ansible commands 
# 
# Parameters : Passed as enviroment variable 
#  SQL = Sentence in SQL 
# 
# Usage example :
#   
# Do a ping against all VM 
# export SQL="SELECT vm from inventario.vmlist  " ; ansible all -i FromITOPtoAnsible.sh -m shell -m "ping"
#
# You can also set variables to ansible, eg :
# export VAR="\"ansible_ssh_pass\" : \"mypassword\" "
# so you can set ssh password to be used.
#
############################################################## 

# Parameters: Change this according to your itop credentials 
MY_USER=change_to_mysql_user
MY_PASS=change_to_mysql__password
MY_SQL_SERVER=change_to_mysql_Server
# End of configurable parameters

TRACE_FILE=/var/log/`basename $0`.log
EXT_FORMAT=no

ShowLog( )
{
   echo [`basename $0`] [`date +'%Y_%m_%d %H:%M:%S'`] [$$] $@  >> $TRACE_FILE
}

# Other parameters

# Get Host List
HOST_LIST=`mysql -u$MY_USER -p$MY_PASSWORD -h$MY_SQL_SERVER -N -e "${SQL}" | sed -e 's/^/\"/g'| sed -e 's/$/\"/g'   | sed ':a;N;$!ba;s/\n/ , /g'`

# If there are defined ext args, we add the _meta section
if [ ${#VAR} -gt 0 ]
then
  echo "{ \"hosts\" : [ ${HOST_LIST} ] ,"

  echo '"_meta" : {'
  echo '  "hostvars" : {'
echo ${HOST_LIST} | sed -e "s/\" /\" : \{ ${VAR} \} /g" |  sed -e "s/\"$/\" : \{ ${VAR} \} /g"
# For earch server, we add the VARiable previously exported
#  for i in `echo ${HOST_LIST} | tr -d \" | tr -d \, `
# do
#   echo " \"$i\" : { ${VAR} }"
# done

  echo '      }'
  echo '   }'
  echo '}'
else
    echo "{ \"hosts\" : [ ${HOST_LIST} ] }"
fi

ROW_NUM=`echo $HOST_LIST | grep -o , | wc -l `

ShowLog "INICIO:"
ShowLog "SQL = \"${SQL}\" "
ShowLog "Executed:  \"${SQL}\", having a total of: ` expr $ROW_NUM + 1 ` results"
ShowLog "Host List :  $HOST_LIST"
ShowLog "Resultados:  ` expr $ROW_NUM + 1 `"
ShowLog "Fin"

