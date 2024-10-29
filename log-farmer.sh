#!/bin/bash

journalctl -n 200 -u autonomys-farmer.service -f --no-hostname -o cat
