
# This script uses FromITOPtoAnsible.sh  FromMysqltoAnsible.sh to execute an operation agains vmware virtual machine list
#
#      Operation to perform:
#  powerOn,powerOff,powerStatus,resetMachine,suspendMachine,

FICHERO_TRAZA=/var/log/inventario/$0.log
FILE_LIST=/tmp/itop_file_list
SCRIPT_FILE=$FILE_LIST.sh
PERL_SCRIPT=/opt/dSNmanivela/sources/src/bin/VMoperations.pl
#######################################################
#
# Funcion MostrarLog
#
# Saca por log el texto pasado por argumento 
# #######################################################
MostrarLog( )
{
         echo [`basename $0`] [`date +'%Y_%m_%d %H:%M:%S'`] [$$] [${FUNCNAME[1]}] $@  | /usr/bin/tee -a $FICHERO_TRAZA }



######  


[ ! -z "$OQL" ] && [ ! -z "$SQL" ] && MostrarLog "Both variables SQL and OQL are defined. Error" && exit 1 [  -z "$OQL" ] && [  -z "$SQL" ] && MostrarLog "None of SQL and OQL variables are defined" && exit 1
 
Generate_VMList( )
{
if [ -z "$OQL" ]
then 
	echo "OQL is unset, SQL"
	/etc/ansible/FromMySQLtoAnsible.sh  | sed -e 's/\,/\n/g'  |  sed -e 's/\:/\n/g' |  grep -v \{  | tr -d \" | tr -d \] | tr -d \} | tr -d \[ |  sed -e 's/^[ ]*//g' > $FILE_LIST else 
	echo "OQL is set to '$OQL'"
	/etc/ansible/FromITOPtoAnsible.sh | sed -e 's/\,/\n/g'  |  sed -e 's/\:/\n/g' |  grep -v \{  | tr -d \" | tr -d \] | tr -d \} | tr -d \[ |  sed -e 's/^[ ]*//g' > $FILE_LIST fi  }

Show_Help( )
{
echo -n"
   $0

   --server (variable VI_SERVER, )
      VI server to connect to. Required
   --password (variable VI_PASSWORD)
      Password. Required
   --username (variable VI_USERNAME)
      Username. Required
   --operation (required)
      Operation to perform:
  powerOn,powerOff,powerStatus,resetMachine,suspendMachine,
"
} 
 
 ARGS=$(getopt -o a:b:c -l "user:,password:,server:,operation:,help:," -n "getopt.sh" -- "$@"); #ARGS=$(getopt -o a:b:c -l ",host:,report:,format:,credential:,credentials:,file:,paramname:,paramvalue:" -n "getopt.sh" -- "$@");

   #--credstore (variable VI_CREDSTORE)
   #  Name of the credential store file defaults to <HOME>/.vmware/credstore/vicredentials.xml
	  
eval set -- "$ARGS";

while true ; do
MostrarLog : Parseamos argumento $1
  case "$1" in
    --user)
      	shift ;
      	vi_user=$1
      	MostrarLog vi_user=$1
      	shift ;
      	continue ;
     ;;
    --password)
        shift ;
        vi_password=$1
        MostrarLog  vi_password=$1
        shift ;
        continue ;
     ;;
    --server)
        shift ;
        vi_center=$1
        MostrarLog vi_center=$1
        shift ;
        continue ;
     ;;
    --operation)
        shift;
        operation=$1
        MostrarLog operation=$1
        shift ;
        continue  ;
		;;
  	*)
      Show_Help
			exit 1
      break ;
          ;;
  esac
done

[  -z "$operation" ] || [  -z "$vi_center" ] || [  -z "$vi_password" ] || [  -z "$vi_user" ] && MostrarLog "Error. Some of the variables --operation $operation --server $vi_center --password $vi_password --user $vi_user no estan definidos " && Show_Help && exit 1

Generate_VMList

> $SCRIPT_FILE

while read vm
do
	# /opt/dSNmanivela/sources/src/bin/VMoperations.pl --vmName test-epg-cmdb-01  --operation powerOn --username maestrodev --password 1maestrodev2 --server prod-epg-vc-01
	echo $PERL_SCRIPT --vmName $vm --operation $operation --username $vi_user --password $vi_password --server $vi_center  >> $SCRIPT_FILE

done < $FILE_LIST 

MostrarLog Ejecutamos la operacion : ${operation}, contra: `cat $SCRIPT_FILE | wc -l  ` maquinas

cat $SCRIPT_FILE
chmod +x $SCRIPT_FILE
. $SCRIPT_FILE 



