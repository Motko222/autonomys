#!/bin/bash

min_conv () {
 a=$1
 case $a in
  "")  out=" " ;;
  "never") out="never" ;;
  0) out="now" ;;
  [1-9]|[1-9][0-9]|1[0-1][0-9]) out=$a"m" ;; #1-119
  1[2-9][0-9]|[2-9][0-9][0-9]|1[0-9][0-9][0-9]|2[0-7][0-9][0-9]|28[0-7][0-9]) out=$((a/60))"h"  ;; #120-2879
  *) out=$((a/60/24))"d" ;;
  esac
 echo $out
}

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) 
folder=$(echo $path | awk -F/ '{print $NF}')
source /root/scripts/$folder/config
source /root/.bash_profile
json=/root/logs/report-$folder
nlog=/root/logs/$folder.node
flog=/root/logs/$folder.farmer
fpid=$(ps aux | grep subspace-farmer | awk '{print $2}')
npid=$(ps aux | grep subspace-node | awk '{print $2}')
network=testnet
chain=$CHAIN

currentblock=$(curl -s -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_syncState", "params":[]}' http://localhost:$WS | jq -r ".result.currentBlock")
if [ -z $currentblock ]; then currentblock=0; fi
#bestblock=$(curl -s -H  POST 'https://subspace.api.subscan.io/api/scan/metadata' --header 'Content-Type: application/json' --header 'X-API-Key: $apiKey' | jq -r .data.blockNum )
bestblock=$(curl -s -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_syncState", "params":[]}' http://localhost:$WS | jq -r ".result.highestBlock")
if [ -z $bestblock ]; then bestblock=0; fi
diffblock=$(($bestblock-$currentblock))
plotted=$(cat $flog | grep --line-buffered --text "Plotting sector " | tail -1 | awk -F "Plotting sector " '{print $2}' | awk '{print $1}' | sed 's/(\|)//g')

temp1=$(grep --line-buffered --text -E "Idle|Syncing|Preparing" $nlog | tail -1)
bdate=$(echo $temp1 | awk '{print $1}')T$(echo $temp1 | awk '{print $2}').000+0200
#bmin=$((($(date +%s)-$(date -d $bdate +%s))/60))
peers=$(echo $temp1 | awk -F " peers" '{print $1}' | awk -F " \(" '{print $2}')
syncSpeed=$(grep --line-buffered --text "Syncing" $nlog | tail -1 | awk -F "Syncing" '{print $2}' | awk -F "," '{print $1}')

#temp2=$(grep --line-buffered --text "Successfully signed reward hash" $flog | tail -1 | sed -r 's/\x1B\[(;?[0-9]{1,3})+[mGK]//g' )
#if [ -z $temp2 ]
#then
# rmin="never";
#else
# rdate=$(echo $temp2 | awk '{print $1}');
# rmin=$((($(date +%s)-$(date -d $rdate +%s))/60))
#fi

rew1=$(cat $flog | grep -a 'Successfully signed reward hash' | grep -c $(date -d "today" '+%Y-%m-%d'))
rew2=$(cat $flog | grep -a 'Successfully signed reward hash' | grep -c $(date -d "yesterday" '+%Y-%m-%d'))
rew3=$(cat $flog | grep -a 'Successfully signed reward hash' | grep -c $(date -d "2 days ago" '+%Y-%m-%d'))
rew4=$(cat $flog | grep -a 'Successfully signed reward hash' | grep -c $(date -d "3 days ago" '+%Y-%m-%d'))
#address=${address1:0:4}...${address1: -4}
size=$(ps aux | grep -w $BASE | grep subspace-farmer-ubuntu | awk -F 'size=' '{print $2}'| awk '{print $1}')
folder=$(du -hs $BASE | awk '{print $1}')
archive=$(ps aux | grep -w $BASE | grep subspace-node-ubuntu | grep -c archive)
#version=$(cat $nlog | grep version | awk '{print $5}' | head -1 | cut -d "-" -f 1 )
version=$(ps aux | grep subspace-node-ubuntu | grep $BASE | awk -F "2024-" '{print $2}' | awk '{print $1}')
balance=$(curl -s POST 'https://subspace.api.subscan.io/api/scan/account/tokens' --header 'Content-Type: application/json' \
 --header 'X-API-Key: '$API'' --data-raw '{ "address": "'$REWARD'" }' | jq -r '.data.native' | jq -r '.[].balance' | awk '{print $1/1000000000000000000}')

[ -z $balance ] && balance="0"

if [ $diffblock -le 5 ]
  then 
    status="ok"
    message="size $size rew $rew1-$rew2-$rew3-$rew4 bal $balance peers $peers"
  else 
    status="warning"
    message="sync $currentblock/$bestblock peers $peers $syncSpeed"; 
fi

if [ $(echo $plotted | cut -d . -f 1) -lt 99 ]
  then 
    status="warning"
    message="size $size plotting $plotted peers $peers"
fi

if [ $bestblock -eq 0 ]
  then 
    status="warning"
    message="cannot fetch network height"
fi

if [ -z $fpid ]
  then 
    status="warning"
    message="farmer not running, sync $currentblock/$bestblock, peers $peers, $syncSpeed"
fi

if [ -z $npid ]
  then 
    status="error"
    message="node not running"
fi

cat >$json << EOF
{
  "updated":"$(date --utc +%FT%TZ)",
  "measurement":"report",
  "tags": {
     "id":"$folder",
     "machine":"$MACHINE",
     "grp":"node",
     "owner":"$OWNER"
  },
  "fields": {
     "version":"$version",
     "status":"$status",
     "message":"$message",
     "fpid":"$fpid",
     "npid":"$npid",
     "peers":"$peers",
     "syncSpeed":"$syncSpeed", 
     "plotted":"$plotted",
     "bestblock":"$bestblock",
     "currentblock":"$currentblock",
     "balance":"$balance"
  }
}
EOF
cat $json | jq
