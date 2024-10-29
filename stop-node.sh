#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) 
folder=$(echo $path | awk -F/ '{print $NF}')

process=$(ps aux | grep subspace-node | grep -v grep | grep "$folder" | awk '{print $2}')
echo "Killing process $process..."
kill $process
