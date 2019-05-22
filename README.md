# picam_livestream

Streams live video from a raspberry pi to a web browser. Uses cloud service (free dyno on heroku) to allow you to view the live stream from anywhere without having to change your home network settings.

Streaming uses jsmpeg (https://github.com/phoboslab/jsmpeg) and the ws_relay concept to be able to view the live stream on a cloud-hosted site.

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

## Explanation of the setup script and how this is working
### Basic concept
One Pi:
* Use python
* Avconv
* About avconv and settings

### Start streaming on reboot
Blah
```
chmod 755 picam_livestream/start.sh
echo "@reboot pi /home/pi/picam_livestream/start.sh" | sudo tee --append /etc/crontab
```

### Create and setup a heroku app
First, download the heroku CLI tool:
```
curl https://cli-assets.heroku.com/install.sh | sh
```

Change to the heroku directory in order to create and deploy to the app
```
cd picam_livestream/heroku
```

Deploying code to heroku is done via git. So setup git credentials and then commit the code in the /heroku directory:
```
git config --global user.email "pi@pi.com"
git config --global user.name "pi user"
git init
git add .
git commit -m "first commit"
```

login to your heroku account and create the app
```
heroku login -i
heroku create
```

deploy the code to heroku:
```
git push heroku master
```

### 


