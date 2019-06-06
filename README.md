# picam_livestream

Streams live video from a raspberry pi to a web browser. Uses cloud service (free dyno on heroku) to allow you to view the live stream from anywhere without having to change your home network settings.

Streaming uses [jsmpeg](https://github.com/phoboslab/jsmpeg) and the ws_relay concept to be able to view the live stream on a cloud-hosted site.

## This assumes:
* you have a raspberry pi 3B or 3A+ (the video encoding requires 4 processors; using a Zero W will be very slow)
* you have a camera module, connected via the ribbon, that is enabled
* you can connect to and work on your pi (e.g., via SSH)
* you have an account with Heroku

## Instructions
First, make sure you you have the following installed on the pi:
```
sudo apt-get install -y python3-pip git libav-tools libffi-dev
pip3 install requests flask_bcrypt
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
2. Create a username and password to be used to login to your heroku site

Once those are complete, you should see the following:
```
ALL DONE! You can find your live stream on:
https://guarded-garden-41222.herokuapp.com
```

The URL is an example Heroku URL. Yours will be different. Go to that site, enter the username and password you created (not the Heroku login) and you should see the live video stream from your Pi!

## The basic concept
Read the [jsmpeg readme](https://github.com/phoboslab/jsmpeg/blob/master/README.md) for a more detailed explanation of jsmpeg. Picam uses jsmpeg.js as well as the ws_relay concept discussed in the readme. 

### server.py
On the Pi, ```server.py``` simply wraps the call to avconv (in the jsmpeg readme he uses ffmpeg) in a retry loop. While avconv by itself can send the stream via POST, if the connection breaks for any reason, avconv stops. This simply pipes the output of avconv to a requests POST call to the Heroku app. If there is a connection error, the error is logged, the program sleeps for 2 seconds and then the POSt is retried. server.py is run via the shell script ```runserver.sh``` that is also simply a retry loop in case server.py itself exits. Then ```start.sh``` does 2 things. First it setups the camera module to run via video4linux. It also runs the runserver.sh script using nohup, so that it runs in the background allowing you can do other things, including disconnecting from SSH.

### Heroku and app.js
The real benefit is using a free dyno from Heroku to host ws_relay and provide a webpage to view the video stream. Most tutorials only get you to the ability to view the live stream while on your home network. If you want to access the video stream from outside of your home network you have to enable port forwarding. 

By using a free dyno on Heroku, you eliminate the need to configure port forwarding. You also don't have to deal with your local IP address changing. And you don't have to worry about dev ops for hosting your own website. Plus you can enable free add-ons (like logging) from Heroku.

```app.js``` is an express app that runs on Heroku. It receives video stream via the POST call from server.py and uses websockets to broadcast the stream to any subscriber. The video is played via jsmpeg on the index page. The site requires login credentials in order to view the video.

### setup.sh
The setup script does a few things (see the script itself for detailed comments):
1. Add start.sh to crontab to run on reboot
2. Create and setup the heroku app (requires user to have a Heroku account and prompts user to login)
3. Updates server.py with the heroku app details
4. Prompts user to create a username and password to use to login to the heroku app
5. Create a unique ID for the stream and save it to server.py and heroku app
6. Run start.sh script to start it!
