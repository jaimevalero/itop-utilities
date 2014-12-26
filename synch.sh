###########################################################
#
# Mapper generation script 
#
###########################################################

###########################################################
#
# Prerequisites:
#
# - You need mysql client installed, and access to mysql server
# - Mysql server has to be in the same server the script is installed
# - Also you need access to itop, with a valid itop user
# 
# The script uses one or more mapping file passed as arguments to generate csv files,
# then executing the import.php webservices, to import the csv into new itop objects.
#
###########################################################

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

HEADER_SECTION=''
BODY_SECTION=''
COUNTER=0 
COLUMNA_ORIGEN=''
COLUMNA_DESTINO=''

HEADER_SECTION_TEMP=''
HEADER_SECTION=''

BODY_SECTION_TEMP=''
BODY_SECTION=''
PROTOCOL=http
CURL_OPTIONS=''

#######################################################
#
# Function PrintLog
#
# Shows a line to screen and log file
#
#######################################################
PrintLog( )
{
   echo [`basename $0`] [`date +'%Y_%m_%d %H:%M:%S'`] [$$]  [${FUNCNAME[1]}] $@  | /usr/bin/tee -a $LOG_FILE
}

# Accumulate Rows to create the mysql used to generate the csv~
AcumulateRows( )
{
    COLUMNA_ORIGEN=` echo $line |cut -d\| -f1`
    COLUMNA_DESTINO=` echo $line |cut -d\| -f2`

    HEADER_SECTION_TEMP=$HEADER_SECTION$COLUMNA_ORIGEN" ,"
    HEADER_SECTION=$HEADER_SECTION_TEMP

    BODY_SECTION_TEMP=$BODY_SECTION\"$COLUMNA_DESTINO\"" ,"
    BODY_SECTION=$BODY_SECTION_TEMP

}

GetWorkingPath( )
{
  # GetWorking Path
  FULL_SCRIPT_PATH=`readlink -f $0`
  WORKING_PATH=`dirname $FULL_SCRIPT_PATH`
}

# Inicio : Clearing enviroment
PreWork( )
{
  GetWorkingPath 
  MY_ID=$$

  clear
  rm -f $WORKING_PATH/spool/*csv
  mkdir -p $WORKING_PATH/spool 2>/dev/null 
  cd $WORKING_PATH 2>/dev/null
  #PrintLog Loading Credentials prwd:$PWD `ls -altr $PWD/.credentials`
  source $PWD/.credentials
   
 # Deleting temp files older than 2 days
  find . -maxdepth 1 -type f -name "tempfile-*" -mtime +2 | xargs rm -f 

  [ ` echo $HTTPS | grep -i Y | wc -l ` -eq 1 ] && PROTOCOL=https && CURL_OPTIONS=' -k ' 

}

CheckPrerequisites( )
{
 # Check mysql access
 mysql -h $MYSQL_HOSTNAME -u${MYSQL_USER} -p${MYSQL_PASS} -e "show databases " 2>/dev/null 1>/dev/null
 RESULT=$?
 [ $RESULT -ne 0 ] && PrintLog "Error checking mysql access. Check credentials provided in the script are correct mysql_host:$MYSQL_HOSTNAME mysql_user:${MYSQL_USER} mysql_pass:${MYSQL_PASS} . Exit" && exit


 # Check webservice exists TODO
}

rawurlencode() {
  local string="${*}"
  local strlen=${#string}
  local encoded=""

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER) 
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

PrintLog START :

PreWork
CheckPrerequisites


# Set config file list 
FILES=`find $WORKING_PATH/config -type f`

# If arguments detected, each argument is a file
[ $# -gt 0 ] && FILES=$*

PrintLog ` ls -1 $FILES | wc -l ` " config file(s) : " $FILES

# Main Loop Iterate through file list
for FILE in `echo $FILES `
do

  COUNTER=$((COUNTER+1))
  PrintLog Config File: $FILE
  # Remove comments and blank lines from the config file  
  grep -v \# $FILE | egrep -v '^ *$'  > $FILE.formatted
  # Remove empty lines
  # sed -i '/^$/d' $FILE.formatted
  
  TABLA_ORIGEN=` head -1 $FILE.formatted |cut -d\; -f1  `
  CLASS_NAME=` head -1 $FILE.formatted | cut -d\; -f2 |tr -d \    `
  RECONCILIATION_KEYS=` head -1 $FILE.formatted | cut -d\; -f3` 
  HEADER_SECTION=''
  BODY_SECTION=''
  # Iterate trough row list  
  while read line         
  do   
    [ ` echo $line | grep  \; | wc -l ` -eq 1 ]  && continue
    AcumulateRows 
  done <$FILE.formatted
  rm -f $FILE.formatted

  HEADER_FINAL=`echo $HEADER_SECTION | sed -e 's/\,$//'`
  BODY_FINAL=`echo $BODY_SECTION | sed -e 's/\,$//'`

  # File paths
  CSV_FILE=$WORKING_PATH/spool/$COUNTER-`basename $FILE |sed -e 's/\.config//g' `_$CLASS_NAME.csv
  SQL_FILE=$WORKING_PATH/spool/$COUNTER-`basename $FILE |sed -e 's/\.config//g' `_$CLASS_NAME.sql

  # Init files 
  rm -f  /tmp/`basename $CSV_FILE`  2>/dev/null
  rm -f $CSV_FILE   2>/dev/null
  rm -f /tmp/kksqlsyn 2>/dev/null

SEPARATOR="|"
  #  Generate SQL
  echo "SELECT $BODY_FINAL " > $SQL_FILE  
  echo "Union ALL (" >> $SQL_FILE
  echo "   SELECT $HEADER_FINAL " >> $SQL_FILE
  echo "   INTO OUTFILE \"/tmp/`basename $CSV_FILE`\"  " >> $SQL_FILE
#  echo "   FIELDS TERMINATED BY \";\" OPTIONALLY ENCLOSED BY '\"' " >> $SQL_FILE
 echo "   FIELDS TERMINATED BY \";\" OPTIONALLY ENCLOSED BY '$SEPARATOR' " >> $SQL_FILE
  echo "   LINES TERMINATED BY \"\\n\" " >> $SQL_FILE
  echo "   FROM $TABLA_ORIGEN " >> $SQL_FILE
  echo " ) " >> $SQL_FILE

  # Execute SQl to generate CSV
  PrintLog "Executing: mysql -h $MYSQL_HOSTNAME -u${MYSQL_USER} -p${MYSQL_PASS} < $SQL_FILE "  
  mysql -h $MYSQL_HOSTNAME -u${MYSQL_USER} -p${MYSQL_PASS} < $SQL_FILE 1>>/tmp/kksqlsyn 2>>/tmp/kksqlsyn
  
  # Test Case : We do not have generated the csv from the sql ( sql is not correct) 
  Resul=$?
  if [ $Resul -ne 0 ] 
  then
    PrintLog "ERROR generating csv file by using: $SQL_FILE , for the config file : $FILE" `cat /tmp/kksqlsyn `
  fi  
  mv /tmp/`basename $CSV_FILE` $CSV_FILE 1>/dev/null
  # Test :  Empty csv file ( Empty file or only header line)
  [ ` cat $CSV_FILE | wc -l ` -le 1 ] &&  PrintLog ERROR generating csv file $CSV_FILE Empty file generated
  rm -f /tmp/kksqlsyn 2>/dev/null    

  PrintLog Results: Generated csv file $CSV_FILE with ` cat  $CSV_FILE | wc -l` rows by using  $SQL_FILE with return code ` [ $Resul -eq 0 ] && echo OK `
  PrintLog "Header of the generated csv file : "` head -2 $CSV_FILE `

  # Tricks to clean the format of the csv
  cat $CSV_FILE | tr \; \, > $CSV_FILE.formatted
  mv -f  $CSV_FILE.formatted $CSV_FILE 
  sed -i 's/\\$//g' $CSV_FILE

  # Encode arguments
  RECONCILIATION_KEYS_ENCODED=$(rawurlencode "$RECONCILIATION_KEYS")
  QUALIFIER_ENCODED=$(rawurlencode "${SEPARATOR}")

  # Execute webservice 
   echo  " curl $CURL_OPTIONS -v -X POST -v --data-urlencode 'csvdata="  > tempfile-$$
   cat $CSV_FILE | tr  "'"  '"' >> tempfile-$$
   echo "' --user $ITOP_USER:$ITOP_PASS -o tempfile-${MY_ID}-2 \"${PROTOCOL}://${ITOP_SERVER}/${INSTALLATION_DIRECTORY}/webservices/import.php?class=${CLASS_NAME}&output=details&charset=UTF-8&reconciliationkeys=${RECONCILIATION_KEYS_ENCODED}&qualifier=${QUALIFIER_ENCODED}\"" >>  tempfile-$$

  # Show results
  PrintLog Execute command : `cat tempfile-$$ `
  PrintLog " Progress webservice execution " 
  chmod +x tempfile-$$ && ./tempfile-$$ 2>/dev/null 
  cat tempfile-${MY_ID}-2 | grep -v ";unchanged;"
  PrintLog Results: `basename $FILE` ` tail -5 tempfile-${MY_ID}-2 ` 

  # Store results for audit purposes
  mv -f tempfile-$$-2 $WORKING_PATH/spool/$COUNTER-`basename $FILE |sed -e 's/\.config//g' `_$CLASS_NAME.results
  rm -f ./tempfile-$$ 
  cp -f $FILE $WORKING_PATH/spool/`basename $FILE` 
 
done

PrintLog END

