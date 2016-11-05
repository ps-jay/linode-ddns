#!/bin/bash

# Validate environment
if [[ -z ${APIKEY} ]] ; then
    echo "Missing APIKEY env var"
    exit 129
fi
if [[ -z ${DOMAIN} ]] ; then
    echo "Missing DOMAIN env var"
    # wget -qO- https://api.linode.com/?api_key="${APIKEY}"\&api_action=domain.list | sed 's/,/\n/g'
    exit 130
fi
if [[ -z ${RECORD} ]] ; then
    echo "Missing RECORD env var"
    # wget -qO- https://api.linode.com/?api_key="${APIKEY}"\&api_action=domain.resource.list\&DomainID="${DOMAIN}" | sed 's/},/}\n/g'
    exit 131
fi

# Main loop
while true ; do

    DATE=`date`

    # Get IP
    WANIP=`wget -qO- http://httpbin.org/ip | grep origin | cut -d '"' -f 4`

    # Validate
    echo ${WANIP} | egrep "^([0-9]{1,3}\.){3}[0-9]{1,3}$" > /dev/null
    if [[ ${?} -eq 0 ]] ; then
        # Update
        RESULT=`wget -qO- https://api.linode.com/?api_key="${APIKEY}"\&api_action=domain.resource.update\&DomainID="${DOMAIN}"\&ResourceID="${RECORD}"\&Target="${WANIP}"`
        echo "${DATE}: ${WANIP} - ${RESULT}"
    else
        # Error condition
        echo "${DATE}: '${WANIP}' not a valid looking IP"
    fi

    sleep 600

done
