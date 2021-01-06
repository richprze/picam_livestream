#v!/usr/bin/env python

###############################
#
# Source: https://github.com/richprze/picam_livestream
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
SECRET = 'REPLACE_WITH_SECRET'
HEROADDR = 'REPLACE_WITH_URL'+SECRET
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

    logger.info("Popen ffmpeg")
    url = HEROADDR
    output = Popen(
        "ffmpeg -loglevel fatal -f v4l2 -video_size 640x480 -r 25 -i /dev/video0 -f mpegts -vf 'vflip, hflip' -vcodec mpeg1video -s 640x480 -b:v 1000k -bf 0 -",
        # Use below if on a Pi Zero W -> need the smaller size
        # "ffmpeg -f v4l2 -video_size 352x288 -i /dev/video1 -f mpegts -vf 'vflip, hflip' -vcodec mpeg1video -s 352x288 -bf 0 -",
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
        except ConnectionRefusedError as err:
            logger.error("ERROR. ConnectionRefusedError: {}".format(err))
        except exceptions.NewConnectionError as err:
            logger.error("ERROR. NewConnectionError: {}".format(err))
        except requests.exceptions.RequestException as err:
            logger.error("ERROR. RequestException: {}".format(err))
        # Bad practice, but don't really care why there is a traceback. just want to retry and keep streaming.
        except:
            logger.error("ERROR. All other exceptions.")
            logger.error(sys.exc_info()[1]) # the error text
        else:
            logger.warning("ELSE. Printing result:")
            logger.warning(res)
        finally:
            # retry since ending up here means the post ended (it should never end since it is constantly streaming data).
            logger.info("Retrying in 2 seconds")
            attempt += 1
            time.sleep(2)

