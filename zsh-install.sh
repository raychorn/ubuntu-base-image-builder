#!/bin/bash
echo "*********************************************"
echo " zsh installer (vanilla)"
echo "*********************************************"
sudo apt-get update -y
sudo apt-get install zsh -y
chsh -s $(which zsh)

echo ""
echo "Finish! Log out of your session and login again. Then run zsh-fancify.sh"