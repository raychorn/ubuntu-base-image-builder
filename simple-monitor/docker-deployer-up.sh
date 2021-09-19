#!/bin/bash

CWD=$(dirname "$0")
PWD=$(pwd)

if [ "$CWD." == ".." ]; then
    CWD=$PWD
    echo "CWD:$CWD"
fi

echo "CWD:$CWD"

export CWD=$CWD

docker-compose -f ./docker-deployer-compose.yml up -d

CNAME=simple-monitor-deployer
CID=$(docker ps | grep $CNAME | awk '{print $1}')

if [ -z "$CID" ]; then
    echo "Failed to start $CNAME"
    exit 1
fi

docker exec -it $CID bash -c "mkdir -p /workspaces"
docker cp ../makevenv.sh $CID:/workspaces/.
docker exec -it $CID bash -c "mkdir -p /workspaces/scripts/utils"
docker cp ../scripts/utils/sort.py $CID:/workspaces/scripts/utils/.
