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

On the Pi, ```server.py``` simply wraps the call to avconv (in the jsmpeg readme he uses ffmpeg) in a retry loop. While avconv by itself can send the stream via POST, if the connection breaks for any reason, avconv stops. This simply restarts it. Then server.py is run from the shell script ```runserver.sh``` that is also simply a retry loop in case server.py itself exits. Then ```start.sh``` runs runserver.sh using nohup. Thus everything will run in the background so you can do other things, including disconnecting from SSH.

The real benefit is using a free dyno from Heroku to host ws_relay and provide a webpage to view the video stream. Most tutorials only get you to the ability to view the live stream while on your home network. If you want to access the video stream from outside of your home network you have to enable port forwarding. 

By using a free dyno on Heroku, you eliminate the need to configure port forwarding. You also don't have to deal with your local IP address changing. And you don't have to worry about dev ops for hosting your own website. Plus you can enable free add-ons (like logging) from Heroku.

## Explanation of the setup script and how this is working
This walks through every command in the setup.sh script.

### Start streaming on reboot
Update /etc/crontab to run the start.sh script on reboot
```
chmod 755 picam_livestream/start.sh
echo "@reboot pi /home/pi/picam_livestream/start.sh" | sudo tee --append /etc/crontab
```

### Create and setup a heroku app
Download and install the Heroku CLI tool:
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
At this point you can access your new heroku app.

### Update server.py with the heroku app URL
Save the app url to a var:
```
read HERO <<< $(heroku apps:info | awk '/===/ { print $2}')
```

Replace the 'REPLACE_WITH_URL' text with the heroku app url:
```
cd ..
sed -i "s/REPLACE_WITH_URL/https:\/\/${HERO}.herokuapp.com\//" server.py
```

### Create a username and password to log into the heroku site
Using python and flask_bcrypt to hash the password. Prompts the user to enter a username and a password twice. Credentials will save to a local file.
```
python3 hash_pass.py
```

The username and password is stored in Heroku via a config variable. The config variable name is the username and the value is the hashed password. First, read the values from the local file and save to a variable:
```
read USER PASS <<< $(cat pass.user | awk '{ print $1, $2}')
```
Then set the config var in heroku:
```
cd heroku
heroku config:set $USER=$PASS
```
### Create a secret ID to identify the stream
Avconv will post to herokuapp.com/streamID and the heroku app will only read from a stream posted to herokuapp.com/streamID. First generate the UUID:
```
UUID=$(cat /proc/sys/kernel/random/uuid)
```
Then set as a config variable in heroku:
```
heroku config:set SECRET=$UUID
```
And replace REPLACE_WITH_SECRET text with the UUID in server.py:
```
cd ..
sed -i "s/REPLACE_WITH_SECRET/${UUID}/" server.py
```

### That's it. 
Final command is to start everything!
```
sudo bash start.sh
```
