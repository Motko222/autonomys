#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) 
folder=$(echo $path | awk -F/ '{print $NF}')
source /root/scripts/$folder/config
source /root/.bash_profile
json=/root/logs/report-$folder
fpid=$(ps aux | grep subspace-farmer | grep -v grep | awk '{print $2}')
npid=$(ps aux | grep subspace-node | grep -v grep | awk '{print $2}')
network=$NETWORK
chain=$CHAIN

currentblock=$(curl -s -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_syncState", "params":[]}' http://localhost:9944 | jq -r ".result.currentBlock")
[ -z $currentblock ] && currentblock=0
#bestblock=$(curl -s -H  POST 'https://subspace.api.subscan.io/api/scan/metadata' --header 'Content-Type: application/json' --header 'X-API-Key: $apiKey' | jq -r .data.blockNum )
bestblock=$(curl -s -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_syncState", "params":[]}' http://localhost:9944 | jq -r ".result.highestBlock")
[ -z $bestblock ] && bestblock=0
diffblock=$(($bestblock-$currentblock))
sync_speed=$(journalctl -u autonomys-node.service --no-hostname -o cat | grep -s "Syncing" | tail -1 | awk -F "Syncing" '{print $2}' | awk -F "," '{print $1}')

rew1=$(journalctl -u autonomys-farmer.service --no-hostname -o cat | grep -a 'Successfully signed reward hash' | grep -c $(date -d "today" '+%Y-%m-%d'))
rew2=$(journalctl -u autonomys-farmer.service --no-hostname -o cat | grep -a 'Successfully signed reward hash' | grep -c $(date -d "yesterday" '+%Y-%m-%d'))
rew3=$(journalctl -u autonomys-farmer.service --no-hostname -o cat | grep -a 'Successfully signed reward hash' | grep -c $(date -d "2 days ago" '+%Y-%m-%d'))
rew4=$(journalctl -u autonomys-farmer.service --no-hostname -o cat | grep -a 'Successfully signed reward hash' | grep -c $(date -d "3 days ago" '+%Y-%m-%d'))
version=$(ps aux | grep subspace-node-ubuntu | grep $BASE | awk -F "2025-" '{print $2}' | awk '{print $1}')
balance=$(curl -s POST 'https://autonomys.api.subscan.io/api/scan/account/tokens' --header 'Content-Type: application/json' \
 --header 'X-API-Key: '$API'' --data-raw '{ "address": "'$REWARD'" }' | jq -r '.data.native' | jq -r '.[].balance' | awk '{print $1/1000000000000000000}')

plotted_percent=$(journalctl -u autonomys-farmer.service --no-hostname -o cat | grep --line-buffered --text "Plotting sector " | grep -a "farm_index="$PLOT_MONITOR | tail -1 | awk -F "Plotting sector " '{print $2}' | awk '{print $1}' | sed 's/(\|)//g' | cut -d . -f 1)%
last_sector_time=$(journalctl -u autonomys-farmer.service --no-hostname -o cat | grep --line-buffered --text "Plotting sector " | grep -a "farm_index="$PLOT_MONITOR | tail -1 | awk '{print $1}')
last_sector_min="$(( ( $(date +%s) - $(date -d $last_sector_time +%s) ) / 60 ))m"
plot_info="$PLOT_MONITOR=$plotted_percent/$last_sector_min "

[ -z $balance ] && balance="0"

if [ $diffblock -le 5 ]
  then 
    status="ok"
    message="rew $rew1-$rew2-$rew3-$rew4 bal $balance"
    url="plot $plot_info"
  else 
    status="warning"
    message="sync $currentblock/$bestblock speed $sync_speed"; 
fi

if [ $bestblock -eq 0 ]
  then 
    status="warning"
    message="cannot fetch network height"
fi

if [ -z $fpid ]
  then 
    status="warning"
    message="farmer not running, sync $currentblock/$bestblock, $sync_speed"
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
     "url":"$plot_info",
     "network":"$network",
     "chain":"$chain",
     "fpid":"$fpid",
     "npid":"$npid",
     "peers":"$peers",
     "sync_speed":"$sync_speed", 
     "plot_info":"$plot_info",
     "bestblock":"$bestblock",
     "currentblock":"$currentblock",
     "balance":"$balance"
  }
}
EOF
cat $json | jq
