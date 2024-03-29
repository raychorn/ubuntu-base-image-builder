#!/bin/bash

CWD=$(dirname "$0")
PWD=$(pwd)

if [ "$CWD." == ".." ]; then
    CWD=$PWD
    echo "CWD:$CWD"
fi

echo "CWD:$CWD"

CNAME=nagios4
CID=$(docker ps | grep $CNAME | awk '{print $1}')

export CWD=$CWD

if [ -z "$CID" ]; then
    docker-compose up -d
else
    docker-compose down
fi
  