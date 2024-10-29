#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) 
folder=$(echo $path | awk -F/ '{print $NF}')

source ~/scripts/$folder/config

read -p "Sure? " c
case $c in
  y)
    if [ ! -d $ssexec ] 
      then
        mkdir $ssexec
    fi
    cd $ssexec
    rm subspace-node* subspace-farmer*
    echo "Get links from here: https://docs.subspace.network/docs/protocol/substrate-cli"
    read -p "Node URL? " url
    wget $url
    read -p "Farmer URL? " url
    wget $url
    node=$(ls | grep subspace-node)
    farmer=$(ls | grep subspace-farmer)
    chmod 777 $node
    chmod 777 $farmer
  ;;
esac
