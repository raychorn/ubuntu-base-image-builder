#!/usr/bin/env bash

PY=$(which python3.9)

sudo add-apt-repository ppa:git-core/ppa -y
sudo apt update -y
sudo apt upgrade -y

if [ ! -f "$PY" ]; then
	sudo add-apt-repository ppa:deadsnakes/ppa -y
	sudo apt install python3.9 python3.9-dev python3.9-venv -y
fi
PY=$(which python3.9)

PIP_TEST=$(pip --version | grep python3.9)
if [ -z "$PIP_TEST" ]; then
	$PY -m ensurepip --default-pip --user
	PIP=$(which pip3.9)
fi

ZSH=$(which zsh)

if [ ! -f "$ZSH" ]; then
	./zsh-install.sh
	./zsh-fancify.sh
fi

sudo apt install docker.io -y
sudo systemctl enable docker
sudo usermod -aG docker $USER
sudo systemctl status docker
sudo groupadd docker
sudo gpasswd -a $USER docker
newgrp docker

cpu_arch=$(uname -m)
echo "cpu_arch:$cpu_arch"

if [ "$cpu_arch" == "x86_64" ]; then
	echo "Installing docker-compose via apt."
	sudo apt-get install docker-compose -y
else
	echo "Installing docker-compose via curl."
	sudo curl -L "https://github.com/docker/compose/releases/download/1.28.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
fi
docker-compose --version
