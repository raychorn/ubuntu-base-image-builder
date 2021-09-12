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
