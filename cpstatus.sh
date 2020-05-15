#!/usr/bin/env bash

STATUS_PORTAL='http://detnsw.net/details.php'

ARGC=$#

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -t|--timeout)
    SHOW_TIMEOUT=1
    shift
    ;;
    -u|--user)
    SHOW_USER=1
    shift
    ;;
    -g|--group)
    SHOW_GROUP=1
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

SHOW_ALL=1
if  [[ "$SHOW_GROUP" -eq 1 || ("$SHOW_USER" -eq 1 || "$SHOW_TIMEOUT" -eq 1) ]]; then
    SHOW_ALL=0
fi

if [[ -z "$INTERFACE" ]]
then
    INTERFACE=`ip -4 route ls |awk '/^default/{print $5}'`
fi




# Read the captive portal
CP_DATA=$(curl --proxy "" --interface "${INTERFACE}" --silent --show-error ${STATUS_PORTAL})

# empty body (302 response) -- need to log in
if [[ -z "CP_DATA" ]]
then
    exit 1
else 
    # parse out the seconds remaining and echo it
    TIMEOUT=$(echo "${CP_DATA}" | grep 'Timeout is' | awk '{ split ($0,a,/<\/?strong>/); print a[2] }')
    USER=$(echo "${CP_DATA}" | grep 'You are authenticated ' | awk '{ split ($0,a,/<\/?strong>/); print a[2] }')
    GROUP=$(echo "${CP_DATA}" | grep 'Your access to ' | awk '{ split ($0,a,/<\/?strong>/); print a[2] }')
    
  
    if [[ $SHOW_ALL -eq 1 || $SHOW_TIMEOUT -eq 1 ]]; then echo $TIMEOUT; fi
    if [[ $SHOW_ALL -eq 1 || $SHOW_USER    -eq 1 ]]; then echo $USER; fi 
    if [[ $SHOW_ALL -eq 1 || $SHOW_GROUP   -eq 1 ]]; then echo $GROUP; fi
fi    
    
#echo "${CP_DATA}"