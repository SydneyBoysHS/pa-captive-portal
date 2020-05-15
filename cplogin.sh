#!/usr/bin/env bash

CAPTIVE_PORTAL='https://edgeportal.det.nsw.edu.au:6082/php/uid.php?vsys=1&rule=4'

ARGC=$#

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -u|--username)
    USERNAME="$2"
    shift
    shift
    ;;
    -p|--password)
    PASSWORD="$2"
    shift
    shift
    ;;
    -i|--interface)
    INTERFACE="$2"
    shift
    shift
    ;;
    *)  # unknown option
    POSITIONAL+=("$1") 
    shift
    ;;
esac
done
set -- "${POSITIONAL[@]}"

if [[ -z "$INTERFACE" ]]
then
    INTERFACE=`ip -4 route ls |awk '/^default/{print $5}'`
fi

if [[ -z "$USERNAME" ]]
then
    echo "Username (-u|--username) is required"
    exit 1
fi;    

if [[ -z "$PASSWORD" ]]
then
    echo "Password (-p|--password) is required"
    exit 1
fi;

# https://stackoverflow.com/a/10660730
rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

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


# Read the captive portal
CP_DATA=$(curl --proxy "" --interface "${INTERFACE}" --silent --show-error ${CAPTIVE_PORTAL})

# Look for the preauthid
PRE_AUTH_ID=$(echo "$CP_DATA" | grep -a thisForm.preauthid.value  | awk -F\" '{print $2}')

if [[ ! -z "PRE_AUTH_ID" ]]
then
    echo 'Got a preauthid. Attempting login'
    
    ENC_USER=$( rawurlencode "$USERNAME" )
    ENC_PASS=$( rawurlencode "$PASSWORD" )
    # TODO escapeUser should replace \ with \\

    #echo $ENC_USER
    #exit 0

    # Perform a login
    CP_RESULT=$(curl --proxy "" --interface "${INTERFACE}"  --silent --show-error  -d "inputStr=&escapeUser=${ENC_USER}&preauthid=${PRE_AUTH_ID}&user=${ENC_USER}&passwd=${ENC_PASS}&ok=Login" -X POST ${CAPTIVE_PORTAL})

    # Look for success string
    # Look for the preauthid
    IS_AUTH=$(echo "$CP_RESULT" | grep -a '<b>User Authenticated</b>')
    
    if [[ ! -z "$IS_AUTH" ]]
    then
        echo 'Authenticated!'
        exit 0
        
    else 
        echo 'Authentication failed. Unknown state'
        echo "$CP_RESULT"
        exit 9
    
    fi
 
else
    echo 'Unknown state'"\n\n"
    echo "$CP_DATA"
    exit 8
fi



