# picam_livestream

Create a live video stream using your raspberry pi and your website (if you don’t have one, this will help you get one for free)! In other words, a DIY nest cam. The stream is nearly instant (< 0.3 second delay) and you don’t need to pay for any special streaming software or to host your own website!

Utilizes [jsmpeg](https://github.com/phoboslab/jsmpeg) to handle stream playback on the website.

## Key components:
* **On the Pi** - runs ffmpeg to stream your live video in the mpegts format to a server
  * ffmpeg is run via python, which handles logging and retries
  * Bash script runs an eternal while loop to restart python script when something goes drastically wrong or when you restart the pi
* **On the Server** - a node js express server hosted on Heroku using the FREE tier (free as in beer!)
  * an express server hosts the website while a websocket server streams the video
  * uses [jsmpeg](https://github.com/phoboslab/jsmpeg) to play the stream on any browser
  * Includes a simple username + password login

## How well does this work?
Very, very well. Checkout two different comparison videos of picam_livestream:
1. Picam_livestream vs. Nest Cam: https://vimeo.com/337640307
1. Compare picam_livestream running on a 3A+ vs. a ZeroW with stopwatch to show actual delay: https://vimeo.com/497717491

## What you need (other than this code)
* A Raspberry Pi with 4 cores is preferred (e.g., 3B or 3A+).
  * The ZeroW will work, but the quality is lower and the delay is greater (~ 4 seconds). Also you have to change the ffmpeg command in server.py
* A camera that connects to the pi. Can connect either via the ribbon or via USB. Here are some suggestions:
  * [The most basic](https://www.amazon.com/gp/product/B00N1YJKFS/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=B00N1YJKFS&linkCode=as2&tag=richiep0d-20&linkId=2776bd51f8ab3f90bf998ea851f2415f)
  * [If you need nightvision](https://www.amazon.com/gp/product/B0829HZ3Q7/ref=as_li_qf_asin_il_tl?ie=UTF8&tag=richiep0d-20&creative=9325&linkCode=as2&creativeASIN=B0829HZ3Q7&linkId=c03e366c7079518c7dfcaf0bb3df19c4)
* Ability to connect to your pi (e.g., headless ssh)
* An account with Heroku. If you don’t have one, go create one. Again it’s free!

## Instructions
If you know what you’re doing and you have everything setup. Getting started is simple:

First, make sure you you have the following installed on the pi:
```
sudo apt-get install -y python3-pip git ffmpeg libffi-dev nodejs
sudo pip3 install bcrypt
```

Second, clone the repo:
```
git clone https://github.com/richprze/picam_livestream.git
```

Third, run the setup script:
```
sudo bash picam_livestream/setup.sh
```

The setup script will have 2 prompts that require your input:
1. Login to your heroku account
1. Create a username and password to be used to login to your heroku site

Once those are complete, you should see the following:
```
ALL DONE! You can find your live stream on:
https://guarded-garden-41222.herokuapp.com
```

The URL is an example Heroku URL. Yours will be different. Go to that site, enter the username and password you created (not the Heroku login) and you should see the live video stream from your Pi!

## The basic concept

### Setup script - setup.sh
The setup script does a few things (see the script itself for detailed comments):
1. Add start.sh to crontab to run on reboot
1. Create and setup the heroku app (requires user to have a Heroku account and prompts user to login)
1. Updates server.py with the heroku app details
1. Prompts user to create a username and password to use to login to the website on heroku
1. Create a unique ID for the stream and save it to server.py and heroku app
1. Run start.sh script to start it!

### On the Pi
Uses ffmpeg to process the live video stream into the mpegts format (read the [jsmpeg readme](https://github.com/phoboslab/jsmpeg/blob/master/README.md) for more details on that)

```server.py``` actually runs ffmpeg and is piping the output of ffmpeg to the heroku app via a continous post call. Python handles logging and retries.

```start.sh``` does 2 things. First it setups the camera module to run via video4linux. Second it runs the runserver.sh script using nohup, so that it runs in the background allowing you to do other things, including disconnecting from SSH.

```runserver.sh```. This is the infinite while loop that is running server.py. Will restart if python or the program borks for any reason.

### Heroku and app.js
```app.js``` is both an express server that hosts the website and a websocket server that handles the streaming of the video. The core is based on [jsmpeg's websocket-relay.js](https://github.com/phoboslab/jsmpeg), but modifies it to run on Heroku and require a login for security. It receives a video stream via the POST call from server.py and uses websockets to broadcast the stream to subscribers. The video is played via jsmpeg on the index page. Jsmpeg is magic. It’s open source and runs on ANY website (since it’s javascript). Not only is it free, but it’s fast. The delay from reality to playing is < 0.3 seconds. Looking around the web I found many examples of 5+ second delays.

Utilizes the free dyno on heroku so you don’t have to pay! The alternatives are to host the website on your pi itself (requiring you to deal with opening up access to your home’s IP address and other headaches of hosting a website yourself) or put the code on an existing website.
