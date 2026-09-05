#!/bin/bash
sudo apt-get install zsh

cn 10 b "INSTALLED"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

if test -t 1; then
csh zsh && exec zsh
fi

    #"Find and change this"
echo "ZSH_THEME=\"robbyrussell\"" <<< ~/.zshrc

 #"To this"
echo "ZSH_THEME=\"agnoster\"" <<< ~/.zshrc

git clone https://github.com/powerline/fonts.git



