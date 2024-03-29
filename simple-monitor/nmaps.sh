#!/bin/bash

PWD=$(pwd)
DIR0=$(dirname $0)

if [ "$DIR0." == ".." ]; then
    DIR0=$PWD
fi

ENVPATH=$DIR0/.env

export $(cat $ENVPATH | sed 's/#.*//g' | xargs)

VENV=$(ls ../.venv*/bin/activate)

if [ ! -f "$VENV" ]; then
    VENV=$(ls ./.venv*/bin/activate)
fi

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

DEFAULT=$(ip r | grep default | awk '{print $3}')

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
            $PY $DIR0/track-ip-addresses.py $line $i "+1" $MAC $DEFAULT
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
            $PY $DIR0/track-ip-addresses.py $line $i "-1" $MAC $DEFAULT
        fi
        IPS="$IPS$line,"
        sleep 5s
    done <<< "$NMAPS"
    echo "IPS:$IPS"
    $PY $DIR0/track-ip-addresses.py --ips $IPS $DEFAULT
    echo "---------------------------------------------------------"
    sleep 5s
done

echo "Done."
