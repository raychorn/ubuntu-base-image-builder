#!/bin/bash

CWD=$(dirname "$0")
PWD=$(pwd)

if [ "$CWD." == ".." ]; then
    CWD=$PWD
    echo "CWD:$CWD"
fi

echo "CWD:$CWD"

docker-compose -f ./zabbix-docker-5.4/docker-compose_v3_ubuntu_mysql_latest.yaml up -d
  