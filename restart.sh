#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) 
folder=$(echo $path | awk -F/ '{print $NF}')

cd ~/scripts/$folder
./start-node.sh
sleep 30s
./start-farmer.sh
