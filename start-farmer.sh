#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) 
folder=$(echo $path | awk -F/ '{print $NF}')
source /root/scripts/$folder/config

echo "Starting farmer $folder ($BASE $REWARD $DISKS)"
cd $EXEC

#./$farmer farm --node-rpc-url $rpc --reward-address $reward path=$base,size=$size &>> ~/logs/subspace_farmer$id &

./$FARMER farm --reward-address $REWARD $DISKS ~/logs/$folder.farmer &
