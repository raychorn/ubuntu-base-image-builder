#!/bin/bash

PWD=$(pwd)
DIR0=$(dirname $0)

if [ "$DIR0." == ".." ]; then
    DIR0=$PWD
fi

SLACK=https://hooks.slack.com/services/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

VENV=$(ls ../.venv*/bin/activate)

if [ ! -f "$VENV" ]; then
    echo "Virtualenv not found. Please fix."
    exit 1
fi

. $VENV

PY=$(which python)
echo "PY:$PY"

if [ ! -f "$PY" ]; then
    echo "$PY not found. Please fix."
    exit 1
fi

declare -A Activities

while true; do

    IPS=""

    NMAPS=$(nmap 10.0.0.0/24 -n -sP | grep report | awk '{print $5}')

    while IFS= read -r line; do
        REPORT=$(sudo nmap -sP -PE -PA21,23,80,3389 $line)
        MAC=$(echo "$REPORT" | grep MAC | awk '{print $3}')
        DOMAIN=$(echo "$REPORT" | grep report | awk '{print $5}')
        ping -w 30 -c 1 $line > /dev/null
        if [ $? -eq 0 ]
        then 
            echo "$line is up"
            i=(${Activities[$line]})
            if [ -z "$i" ]; then
                Activities[$line]=1
            else
                Activities[$line]=$((i+1))
            fi
            i=(${Activities[$line]})
            echo "i -> $i"
            $PY $DIR0/track-ip-addresses.py $line $i
        else
            echo "$line is down"
            i=(${Activities[$line]})
            if [ -z "$i" ]; then
                Activities[$line]=1
            else
                Activities[$line]=$((i-1))
            fi
            i=(${Activities[$line]})
            echo "i -> $i"
            curl -X POST -H 'Content-type: application/json' --data '{"text":"$line is down"}' $SLACK
            $PY $DIR0/track-ip-addresses.py $line $i
        fi
        if [[ $MAC =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]]; then
            echo "Issuing wakeonlan for $MAC"
            wakeonlan $MAC
        fi
        IPS="$IPS$line,"
    done <<< "$NMAPS"
    echo "IPS:$IPS"
    $PY $DIR0/track-ip-addresses.py --ips $IPS $SLACK
    echo "---------------------------------------------------------"

done

echo "Done."
