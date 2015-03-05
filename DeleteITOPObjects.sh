
##############################################################
#
# This script DELETES Objects by defining it in a OQL CONSULT
# 
#  OQL = Sentence in OQL l, 
#      eg export OQL="SELECT Server WHERE status = 'stock'"
#
# 
# Usage example :
#   Just export the OQL and executes the script   
#
############################################################## 
# TODO: It does NOT delete objects under https. 

# Condfigurable parameters: Change this according to your itop credentials 
# Change according your installation directory name : eg itop-itsm

CREDENTIALS_FILE=.credentials

# End of configurable parameters

# Other non configurable parameters
HEADER='Content-Type: application/json'
INITIAL="%7B%0A%20%20%20%22operation%22%3A%20%22core%2Fdelete%22%2C%0A%20%20%20%22class%22%3A%20%22CLASS%22%2C%0A%20%20%20%22key%22%3A%20%22OQL%22%0A%7D%0A%0A"
LOG_FILE=/var/log/` basename $0`
# End of non configurable parameters
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

GetWorkingPath( )
{
  # GetWorking Path
  FULL_SCRIPT_PATH=`readlink -f $0`
  WORKING_PATH=`dirname $FULL_SCRIPT_PATH`
}

# Inicio : Clearing enviroment
PreWork( )
{
  PrintLog Start $OQL
  [ ` echo $OQL | grep SELECT | wc -l ` -ne 1 ] &&  PrintLog OQL variable not exported :$OQL 
  GetWorkingPath 
 
  clear
  cd $WORKING_PATH 2>/dev/null
  #PrintLog Loading Credentials prwd:$PWD `ls -altr $PWD/.credentials`
  source $PWD/.credentials


} 
PrepareCURL( )
{
# Build URL
URL="http://${ITOP_SERVER}/${INSTALLATION_DIRECTORY}/webservices/rest.php?version=1.0&auth_user=${ITOP_USER}&auth_pwd=${ITOP_PASS}"

# Get text replacements
CLASS=`echo $OQL | awk '{print $2}'`
OQL_ENCODED=` urlencode "$OQL"`

# Perform text replacement
RAW=`echo $INITIAL | sed -e "s/CLASS/$CLASS/g" | sed -e "s/OQL/$OQL_ENCODED/g" `
}

PerformCURL( )
{
PrintLog "Executing curl -X POST -v -H "$HEADER" \"$URL&json_data=$RAW\" "
curl -X POST -v -H "$HEADER" "$URL&json_data=$RAW" | jq . > salida-$$

cat salida-$$ | jq .
cat salida-$$  >> $LOG_FILE

}

PostWork( )
{
rm -f salida-$$
PrintLog END
}
############################
# Main
############################

# Prepare URL
PreWork

# PrepareCURL
PrepareCURL

# Perform CURL
PerformCURL

# Delete temp files
PostWork


exit 0


