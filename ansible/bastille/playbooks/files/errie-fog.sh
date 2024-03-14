#!/bin/bash

mkdir $HOME/git
git clone --bare https://github.com/jonathanchancey/dotfiles $HOME/git/.dotfiles
alias config='/usr/bin/git --git-dir=$HOME/git/.dotfiles --work-tree=$HOME'
rescheck() {
  config restore --staged "$@"
  config checkout --theirs "$@"
}
config status
config checkout errie-fog
