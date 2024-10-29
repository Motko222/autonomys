#!/bin/bash

journalctl -n 200 -u autonomys-node.service -f --no-hostname -o cat
