#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) 
folder=$(echo $path | awk -F/ '{print $NF}')
source ~/scripts/$folder/config
node=$(ls $EXEC | grep subspace-node)

echo "Starting node $folder ($BASE $node $CHAIN $NAME $PEERS)"
cd $EXEC

#./$node run --chain $chain --base-path $base --farmer --listen-on /ip4/0.0.0.0/tcp/$port --rpc-listen-on 127.0.0.1:$wsport \
#    --in-peers $peers --out-peers $peers --name $name &> ~/logs/subspace_node$id &

./$node run --chain $CHAIN --base-path "$BASE" --name "$NAME" --farmer --listen-on /ip4/0.0.0.0/tcp/$PORT --rpc-listen-on 127.0.0.1:$WS &> ~/logs/$folder.node &
tail -f ~/logs/$folder.node
