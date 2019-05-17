#!/bin/bash
sudo modprobe bcm2835-v4l2
nohup /home/pi/picam_livestream/runserver.sh > /home/pi/picam_livestream/server.log &
