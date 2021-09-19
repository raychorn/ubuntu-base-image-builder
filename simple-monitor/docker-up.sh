#!/bin/bash

CWD=$(dirname "$0")
PWD=$(pwd)

if [ "$CWD." == ".." ]; then
    CWD=$PWD
    echo "CWD:$CWD"
fi

echo "CWD:$CWD"

CNAME=simple-monitor
CID=$(docker ps | grep $CNAME | awk '{print $1}')

export CWD=$CWD

if [ -z "$CID" ]; then
    docker-compose -f ./docker-compose.yml up -d
else
    docker-compose -f ./docker-compose.yml down
fi
  