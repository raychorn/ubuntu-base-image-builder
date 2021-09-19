#!/bin/bash

PWD=$(pwd)
DIR0=$(dirname $0)

if [ "$DIR0." == ".." ]; then
    DIR0=$PWD
fi
echo "DIR0=$DIR0"
echo "PWD=$PWD"

VENV=~/.venv
REQS=$DIR0/requirements.txt

PYTHON39=$(which python3.9)
PIP3=$(which pip3)

echo "python39=$PYTHON39"
echo "PIP3=$PIP3"

add-apt-repository ppa:git-core/ppa -y

apt-get update -y

apt install git -y

apt-get upgrade -y
apt-get install net-tools -y
apt install iputils-ping -y

apt install nmap -y

apt install curl wget unzip gpg -y

apt-get install wakeonlan -y

export DEBIAN_FRONTEND=noninteractive
export TZ=America/Denver

apt-get install -y tzdata wget nano

apt-get install jq -y

apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
ARCH_TEST=$(uname -p)
if [ "$ARCH_TEST" == "x86_64" ]; then
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
else
    add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
fi
apt update -y
apt install docker-ce -y
usermod -aG docker ${USER}

curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

sleeping () {
    while true; do
        echo "Sleeping... this is what this is supposed to do but this keesp the container running forever and it is doing wakeonlan's."
        sleep 9999s
    done
}

DOCKER_COMPOSE_TEST=$(docker-compose --version | grep "docker-compose version")
echo "Docker Compose Test #1: $DOCKER_COMPOSE_TEST"

if [ -z $DOCKER_COMPOSE_TEST ]; then
    echo "Docker Compose not installed? Trying to resolve."
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

DOCKER_COMPOSE_TEST2=$(docker-compose --version | grep "docker-compose version")
echo "Docker Compose Test #2: $DOCKER_COMPOSE_TEST2"

if [ -z $DOCKER_COMPOSE_TEST2 ]; then
    echo "Docker Compose not installed. Cannot continue."
    sleeping
fi

if [ -z "$PYTHON39" ]; then
    echo "Python 3.9 is not installed. Installing now..."
    apt-get update -y
    apt install software-properties-common -y
    add-apt-repository ppa:deadsnakes/ppa -y
    apt-get install python3.9 -y
    PYTHON39=$(which python3.9)
fi

if [ -z "$PIP3" ]; then
    echo "Pip 3 is not installed. Installing now..."
    apt-get install python3-pip -y
    PIP3=$(which pip3)
fi

PYTHON39=$(which python3.9)
PIP3=$(which pip3)

echo "PYTHON39=$PYTHON39"
echo "PIP3=$PIP3"

#################################################
###  BEGIN: Simulated Build Environment  ########
#################################################

VIRTUALENV=$(which virtualenv)

if [ -z "$VIRTUALENV" ]; then
    echo "Virtualenv is not installed. Installing now..."
    $PIP3 install virtualenv
fi

VIRTUALENV=$(which virtualenv)
if [ -f "$VIRTUALENV" ]; then
    echo "$VIRTUALENV exists."
else
    echo "ERROR: $VIRTUALENV was not installed.  Cannot continue."
    sleeping
fi

$VIRTUALENV --python $PYTHON39 -v $VENV

if [ -f "$VENV/bin/activate" ]; then
    echo "$VENV/bin/activate exists."
else
    echo "ERROR: $VENV/bin/activate was not installed.  Cannot continue."
    sleeping
fi

. $VENV/bin/activate

PYTHON39=$(which python3.9)
PIP3=$(which pip3)

echo "PYTHON39=$PYTHON39"
echo "PIP3=$PIP3"

PIPTEST=$(pip3 --version)
echo "PIPTEST=$PIPTEST"

if [ -f "$REQS" ]; then
    echo "$REQS exists."
    $PIP3 install -r $REQS
else
    if [ -f "$PIP3" ]; then
        echo "Importing Python REQS"
        $PIP3 install python-dotenv
        $PIP3 install requests
        $PIP3 install ujson
        $PIP3 install dnspython
        $PIP3 freeze > $REQS
    else
        echo "ERROR: Cannot configure AWS from .env using $PYFILE.  Cannot continue."
        sleeping
    fi
fi

#################################################
###  END!!! Simulated Build Environment  ########
#################################################

git clone https://github.com/raychorn/ubuntu-base-image-builder.git

INSTALLER=/ubuntu-base-image-builder/simple-monitor

if [ -d "$INSTALLER" ]; then
    echo "Found $INSTALLER"
else
    echo "ERROR: $INSTALLER was not found.  Cannot continue."
    sleeping
fi

cd $INSTALLER
docker-compose -f ./docker-compose.yml up -d

CNAME=simple-monitor
CID=$(docker ps | grep $CNAME | awk '{print $1}')

if [ -z "$CID" ]; then
    echo "ERROR: $CNAME was not started.  Cannot continue."
    sleeping
else
    echo "Container $CNAME started with ID $CID"
fi

docker exec -it $CID bash -c "mkdir -p /workspaces"
for FILE in ./*; do docker cp $FILE $CID:/workspaces; done

echo "Done."

sleeping
