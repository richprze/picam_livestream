#!/bin/bash

#### 1. Update /etc/crontab to run the start.sh script on reboot ####
echo "setting up crontab reboot"
chmod 755 picam_livestream/start.sh
echo "@reboot pi sudo bash /home/pi/picam_livestream/start.sh" | sudo tee --append /etc/crontab

#### 2. Create and Setup Heroku App ####

# Download and install the Heroku CLI tool:
echo "download heroku cli"
curl https://cli-assets.heroku.com/install.sh | sh

echo "change to heroku directory"
cd picam_livestream/heroku
pwd

# Deploying code to heroku is done via git. So setup git credentials and then commit the code in the /heroku directory:
echo "setup git credentials"
git config --global user.email "pi@pi.com"
git config --global user.name "pi user"

echo "git commit"
git init
git add .
git commit -m "first commit"

# login to your heroku account and create the app
echo "login to your heroku account"
read SUCC <<< $(heroku login -i | awk '/Logged in as/ {print}')
if [[ -z $SUCC ]]; then
	echo "login failed. You have 1 more try. Make sure your password is correct!"
	read SUCC <<< $(heroku login -i | awk '/Logged in as/ {print}')
fi

echo "create the heroku app"
heroku create

# deploy the code to Heroku
echo "deploy the code to heroku"
git push heroku master

# NOTE: at this point you can access your heroku app. You will see a login form

#### 3. Update server.py with the heroku app URL ####

# Parse the output of heroku CLI apps command to save the URL to a variable
echo "get the heroku website url"
read HERO <<< $(heroku apps:info | awk '/===/ { print $2}')

echo "change back to the main directory"
cd ..

# Replace the 'REPLACE_WITH_URL' text with the heroku app url
echo "replace with your heroku website url"
sed -i "s/REPLACE_WITH_URL/https:\/\/${HERO}.herokuapp.com\//" server.py

#### 4. Create a username and password to log into the heroku site ####

# Using python and flask_bcrypt to hash the password. Prompts the user to enter a username and a password twice. Credentials will save to a local file.
echo "create a username and password for your website."
echo "enter a username and password, twice:"
python3 hash_pass.py

# The username and password is stored in Heroku via a config variable. The config variable name is the username and the value is the hashed password. First, read the values from the local file and save to a variable.
echo "set the username and hashed password as a heroku config variable"
read USER PASS <<< $(cat pass.user | awk '{ print $1, $2}')
cd heroku
heroku config:set $USER=$PASS

#### 5. Create a secret ID to identify the stream ####
# Avconv will post to herokuapp.com/streamID and the heroku app will only read from a stream posted to herokuapp.com/streamID. First generate the UUID.
echo "create and set the secret to a heroku config variable"
UUID=$(cat /proc/sys/kernel/random/uuid)

# Then set as a config variable in heroku:
heroku config:set SECRET=$UUID

# And replace REPLACE_WITH_SECRET text with the UUID in server.py
echo "replace with your secret"
cd ..
sed -i "s/REPLACE_WITH_SECRET/${UUID}/" server.py

#### 6. Start it! ####
echo "start it up!"
sudo bash start.sh

echo " "
echo "ALL DONE! You can find your live stream on:"
echo "https://$HERO.herokuapp.com"
