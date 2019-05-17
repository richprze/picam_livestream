#!/bin/bash
while true; do
	python3 -u /home/pi/picam_livestream/server.py
	sleep 1
	echo "["$(date)"] restarting" >> /home/pi/picam_livestream/server.log
done
