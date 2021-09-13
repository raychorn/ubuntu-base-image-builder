#!/usr/bin/env bash

sudo add-apt-repository ppa:git-core/ppa -y
sudo apt update -y
sudo apt upgrade -y

sudo add-apt-repository ppa:deadsnakes/ppa -y

sudo apt install python3.9 python3.9-dev python3.9-venv -y

$(which python3.9) -m ensurepip --default-pip --user

./zsh-install.sh

./zsh-fancify.sh

sudo apt install docker.io -y
sudo systemctl enable docker
sudo usermod -aG docker $USER
sudo systemctl status docker
sudo groupadd docker
sudo gpasswd -a $USER docker
newgrp docker
docker container run hello-world

cpu_arch=$(uname -m)

if [[ "$cpu_arch" != "x86_64" ]]
then
	sudo apt-get install docker-compose -y
else
	sudo curl -L "https://github.com/docker/compose/releases/download/1.28.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
fi
docker-compose --version

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

PY=$(which python3.9)

if [[ ! -f "$PY" ]]; then
	echo "Python 3.9 is unavailable.  Please fix."
	exit 1
fi

ZSHRC=$HOME/.zshrc

if [[ ! -f "$ZSHRC" ]]; then
	echo "ZSHRC is unavailable.  Please fix."
	exit 1
fi

TEMP_PY_FILE=/tmp/py_util.py
cat << TEMP_PY_FILE_EOF > $TEMP_PY_FILE
import sys
import os

assert os.path.exists(sys.argv[1]), '{} does not exist'.format(sys.argv[1])

assert (sys.argv[3]) and (len(sys.argv[3]) > 0), '{} is empty'.format('sys.argv[3]')
assert (sys.argv[4]) and (len(sys.argv[4]) > 0), '{} is empty'.format('sys.argv[4]')

__is__ = False
__might__ = False
with open(sys.argv[1], "r") as fIn:
    with open(sys.argv[2], "w") as fOut:
        for line in fIn:
            __might__ = (line.find(sys.argv[3]) > -1)
            fOut.write(line.replace(sys.argv[3], sys.argv[4]))
            if (__might__):
                __is__ = True

if (__is__):
    os.rename(sys.argv[1], sys.argv[1] + '.bak')
    os.rename(sys.argv[2], sys.argv[1])

TEMP_PY_FILE_EOF

if [[ ! -f "$TEMP_PY_FILE" ]]; then
    echo "TEMP_PY_FILE is unavailable.  Please fix."
    exit 1
fi

$PY $TEMP_PY_FILE $ZSHRC $ZSHRC.new "ZSH_THEME=\"robbyrussell\"" "ZSH_THEME=\"powerlevel10k/powerlevel10k\""

if [[ ! -f "$ZSHRC.new" ]]; then
    echo "$ZSHRC has been updated."
else
    echo "$ZSHRC has not been updated."
fi
