#v!/usr/bin/env python

###############################
#
# Source: https://github.com/richprze/picamstream
# Author: richprze
#
###############################

import sys
import requests
import time
import logging
from logging.handlers import RotatingFileHandler
from urllib3 import exceptions
from subprocess import Popen, PIPE


###############################
# CONFIGURATION
HTTP_PORT = 8089 #4560
SECRET = '261a9635-e30b-4777-9484-71d29bd42292'
HEROADDR = 'https://gentle-bayou-10830.herokuapp.com/'+SECRET
ERROR1 = "[Errno 104] Connection reset by peer"
ERROR2 = "Remote end closed connection without response"
###############################


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
handler = RotatingFileHandler('/home/pi/picam_livestream/server.log', maxBytes=1000000, backupCount=3)
handler.setLevel(logging.DEBUG)
formatter = logging.Formatter("[%(asctime)s] {%(lineno)d} %(levelname)s - %(message)s")
handler.setFormatter(formatter)

logger.addHandler(handler)

if __name__ == '__main__':

    logger.info("Popen avconv")
    url = HEROADDR
    output = Popen(
        "avconv -loglevel fatal -f v4l2 -video_size 640x480 -r 25 -i /dev/video0 -f mpegts -vf 'vflip, hflip' -vcodec mpeg1video -s 640x480 -b:v 1000k -bf 0 -",
        stdout=PIPE, stderr=sys.stdout, shell=True)

    attempt = 0
    while True:
        try:
            logger.info("Try attempt #{}".format(attempt))
            res = requests.post(url, data=output.stdout, stream=True)
        except requests.exceptions.ConnectionError as err:
            if (str(err).strip() == ERROR1 or str(err).strip() == ERROR2):
                logger.error("ERROR. ConnectionError (passing): {}".format(err))
                pass
            else:
                logger.error("ERROR. ConnectionError: {}".format(err))
                logger.info("Retrying in 2 seconds")
                attempt += 1
                time.sleep(2)
        except ConnectionRefusedError as err:
            logger.error("ERROR. ConnectionRefusedError: {}".format(err))
            logger.info("Retrying in 2 seconds")
            attempt += 1
            time.sleep(2)
        except exceptions.NewConnectionError as err:
            logger.error("ERROR. NewConnectionError: {}".format(err))
            attempt += 1
            time.sleep(2)
        except requests.exceptions.RequestException as err:
            logger.error("ERROR. RequestException: {}".format(err))
            logger.info("Retrying in 2 seconds")
            attempt += 1
            time.sleep(2)
        except:
            logger.error("ERROR. All other exceptions.")
            logger.error(sys.exc_info()[1]) # the error text
            attempt += 1
            time.sleep(2)
        else:
            logger.warning("ELSE. Printing result:")
            logger.warning(res)
            logger.info("Breaking out of while loop on attempt #{}".format(attempt))
            attempt += 1
            time.sleep(2)
            break

