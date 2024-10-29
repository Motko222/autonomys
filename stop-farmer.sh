#!/bin/bash

process=$(ps aux | grep subspace-farmer | grep -v grep | grep $folder | awk '{print $2}')
echo "Killing process $process..."
kill $process
