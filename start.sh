#!/bin/bash
sudo modprobe bcm2835-v4l2
nohup /home/pi/picamstream/runserver.sh > /home/pi/picamstream/log_server.out &
