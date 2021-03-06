#!/bin/bash
# Based on:
# https://github.com/Powerlevel9k/powerlevel9k/wiki/Install-Instructions
# https://github.com/ohmyzsh/ohmyzsh
# https://powerline.readthedocs.io/en/latest/installation/linux.html#fonts-installation
# https://gist.github.com/dogrocker/1efb8fd9427779c827058f873b94df95
# https://linuxhint.com/install_zsh_shell_ubuntu_1804/

echo "*********************************************"
echo " zsh fancifier"
echo "*********************************************"
echo ""
echo "1. Installing oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

echo ""
echo "2. Installing powerlevel9k theme (legacy)..."
git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
sed -i 's@^ZSH_THEME=.*$@ZSH_THEME="powerlevel9k/powerlevel9k"@g' ~/.zshrc

echo ""
echo "3. Installing powerline fonts..."
wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
wget https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf
mkdir -p ~/.local/share/fonts/
mv PowerlineSymbols.otf ~/.local/share/fonts/
fc-cache -vf ~/.local/share/fonts/
mkdir -p ~/.config/fontconfig/conf.d/
mv 10-powerline-symbols.conf ~/.config/fontconfig/conf.d/

echo ""
echo "4. Installing autosuggestions and syntax highlighting..."
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
sed -i 's@plugins=(git)@plugins=(git zsh-autosuggestions zsh-syntax-highlighting)@g' ~/.zshrc

echo ""
echo "Finish! Log out of your session and login again."
