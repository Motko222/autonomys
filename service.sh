#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) 
folder=$(echo $path | awk -F/ '{print $NF}')
source /root/scripts/$folder/config

node=$(ls $EXEC | grep subspace-node)
farmer=$(ls $EXEC | grep subspace-farmer)

sudo tee /etc/systemd/system/autonomys-node.service > /dev/null <<EOF
[Unit]
Description=autonomys-node
After=network.target
[Service]
User=root
ExecStart=$EXEC/$node run --chain $CHAIN --base-path $BASE --name $NAME --farmer
Restart=always
RestartSec=30
[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/autonomys-farmer.service > /dev/null <<EOF
[Unit]
Description=autonomys-farmer
After=network.target
[Service]
User=root
ExecStart=$EXEC/$farmer farm --reward-address $REWARD $DISKS --farm-during-initial-plotting
Restart=always
RestartSec=30
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable autonomys-node
sudo systemctl enable autonomys-farmer
