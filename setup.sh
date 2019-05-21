#!/bin/bash

echo "setting up crontab reboot"
chmod 755 picam_livestream/start.sh
echo "@reboot pi /home/pi/picam_livestream/start.sh" | sudo tee --append /etc/crontab

echo "download heroku cli"
curl https://cli-assets.heroku.com/install.sh | sh

echo "change to heroku directory"
cd picam_livestream/heroku
pwd

echo "setup git credentials"
git config --global user.email "pi@pi.com"
git config --global user.name "pi user"

echo "git commit"
git init
git add .
git commit -m "first commit"

echo "login to your heroku account"
heroku login -i

echo "create the heroku app"
heroku create

# echo "set buildpack"
# heroku buildpacks:set heroku/nodejs

echo "deploy the code to heroku"
git push heroku master

echo "get the heroku website url"
read HERO <<< $(heroku apps:info | awk '/===/ { print $2}')

echo "change back to the main directory"
cd ..

echo "replace with your heroku website url"
sed -i "s/REPLACE_WITH_URL/https:\/\/${HERO}.herokuapp.com\//" server.py

echo "create a username and password for your website."
echo "enter a username and password, twice:"
python3 hash_pass.py

echo "set the username and hashed password as a heroku config variable"
read USER PASS <<< $(cat pass.user | awk '{ print $1, $2}')
cd heroku
heroku config:set $USER=$PASS

echo "create and set the secret to a heroku config variable"
UUID=$(cat /proc/sys/kernel/random/uuid)
heroku config:set SECRET=$UUID
echo "replace with your secret"
cd ..
sed -i "s/REPLACE_WITH_SECRET/${UUID}/" server.py

echo "start it up!"
sudo bash start.sh

echo " "
echo "ALL DONE! You can find your live stream on:"
echo "https://$HERO.herokuapp.com"
