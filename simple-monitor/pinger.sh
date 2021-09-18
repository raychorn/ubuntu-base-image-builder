#!/bin/bash

RESP=$(ping -w 10 -c 1 $1 | tail -n 2 | head -n 1 | awk '{print $6}')
echo $RESP