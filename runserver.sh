#!/bin/bash
while true; do
	python3 -u /home/pi/picamstream/server.py
	sleep 1
	echo "["$(date)"] restarting" >> /home/pi/picamstream/server.log
done
