#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) 
folder=$(echo $path | awk -F/ '{print $NF}')
source ~/scripts/$folder/config

[ ! -d $BASE ] && mkdir $BASE

echo "Starting node $folder ($BASE $NODE $CHAIN $PORT $WS $NAME $PEERS)"
cd $EXEC

#./$node run --chain $chain --base-path $base --farmer --listen-on /ip4/0.0.0.0/tcp/$port --rpc-listen-on 127.0.0.1:$wsport \
#    --in-peers $peers --out-peers $peers --name $name &> ~/logs/subspace_node$id &

./$NODE run --chain $CHAIN --base-path "$BASE" --name "$NAME" --farmer &> ~/logs/$folder.node &
