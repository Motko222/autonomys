#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) 
folder=$(echo $path | awk -F/ '{print $NF}')

cd ~/scripts/$folder
git stash push --include-untracked
git pull
chmod +x *.sh
