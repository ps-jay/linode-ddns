#!/bin/bash

# Validate environment
if [[ -z ${DNSNAME} ]] ; then
    echo "Missing DNSNAME env var"
    exit 128
fi
if [[ -z ${APIKEY} ]] ; then
    echo "Missing APIKEY env var"
    exit 129
fi
if [[ -z ${DOMAINID} ]] ; then
    echo "Missing DOMAINID env var"
    # wget -qO- https://api.linode.com/?api_key="${APIKEY}"\&api_action=domain.list | sed 's/,/\n/g'
    exit 130
fi
if [[ -z ${RECORDID} ]] ; then
    echo "Missing RECORDID env var"
    # wget -qO- https://api.linode.com/?api_key="${APIKEY}"\&api_action=domain.resource.list\&DomainID="${DOMAINID}" | sed 's/},/}\n/g'
    exit 131
fi

LOOPTIME=600
if [[ -z ${SLEEPTIME} ]] ; then
    echo "Missing SLEEPTIME env var, defaulting to ${LOOPTIME}"
else
    LOOPTIME=${SLEEPTIME}
fi

# It's handy to know it all works first time though
FIRSTEXEC="true"

# Main loop
while true ; do

    DATE=`date`

    # Get current DNS record
    # Note: very much a busybox specific nslookup format here .. also might only work for CNAMES?
    CURRENT=`nslookup ${DNSNAME} | tail -n 1 | cut -d ":" -f 2 | cut -d " " -f 2`

    # Validate current DNS record
    echo ${CURRENT} | egrep "^([0-9]{1,3}\.){3}[0-9]{1,3}$" > /dev/null
    if [[ ${?} -ne 0 ]] ; then
        # Error condition
        echo "${DATE}: '${CURRENT}' not a valid looking IP"
        sleep ${LOOPTIME}
        continue
    fi

    # Get public IP
    PUBLICIP=`wget -qO- http://httpbin.org/ip | grep origin | cut -d '"' -f 4`

    # Validate public IP
    echo ${PUBLICIP} | egrep "^([0-9]{1,3}\.){3}[0-9]{1,3}$" > /dev/null
    if [[ ${?} -ne 0 ]] ; then
        # Error condition
        echo "${DATE}: '${PUBLICIP}' not a valid looking IP"
        sleep ${LOOPTIME}
        continue
    fi

    if [[ ${FIRSTEXEC} == "true" ]] ; then
        echo "Current DNS record: ${CURRENT}"
        echo "Current public IP : ${PUBLICIP}"
        FIRSTEXEC="false"
    fi

    if [[ ${CURRENT} != ${PUBLICIP} ]] ; then
        # Update
        RESULT=`wget -qO- https://api.linode.com/?api_key="${APIKEY}"\&api_action=domain.resource.update\&DomainID="${DOMAINID}"\&ResourceID="${RECORDID}"\&Target="${PUBLICIP}"`
        echo "${DATE}: ${CURRENT} != ${PUBLICIP}, updated: ${RESULT}"
    fi

    sleep ${LOOPTIME}

done
