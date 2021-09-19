#!/bin/bash

CWD=$(dirname "$0")
PWD=$(pwd)

if [ "$CWD." == ".." ]; then
    CWD=$PWD
    echo "CWD:$CWD"
fi

echo "CWD:$CWD"

export CWD=$CWD

docker-compose -f ./docker-deployer-compose.yml down --remove-orphans
  