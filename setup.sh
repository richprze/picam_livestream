#!/bin/bash

echo "setting up crontab reboot"
chmod 755 picam_livestream/start.sh
echo "@reboot pi /home/pi/picam_livestream/start.sh" | sudo tee --append /etc/crontab

echo "download heroku cli"
curl https://cli-assets.heroku.com/install.sh | sh

echo "cd heroku"
cd picam_livestream/heroku
pwd

echo "setup git creds"
git config --global user.email "pi@pi.com"
git config --global user.name "pi user"

echo "git commit"
git init
git add .
git commit -m "first commit"

echo "heroku login"
heroku login -i

echo "heroku create"
heroku create

# echo "set buildpack"
# heroku buildpacks:set heroku/nodejs

echo "heroku push master"
git push heroku master

echo "get url"
read HERO <<< $(heroku apps:info | awk '/===/ { print $2}')

echo "cd .."
cd ..

echo "replace with url"
sed -i "s/REPLACE_WITH_URL/https:\/\/${HERO}.herokuapp.com\//" server.py

echo "hash_pass"
python3 hash_pass.py

echo "read pass"
read USER PASS <<< $(cat pass.user | awk '{ print $1, $2}')

echo "cd heroku"
cd heroku

echo "set heroku config"
heroku config:set $USER=$PASS

echo "create and set secret to config"
UUID=$(cat /proc/sys/kernel/random/uuid)
heroku config:set SECRET=$UUID

echo "cd .."
cd ..

echo "replace secret"
sed -i "s/REPLACE_WITH_SECRET/${UUID}/" server.py

echo "starting"
sudo bash start.sh

echo " "
echo "ALL DONE! You can find your live stream on:"
echo "https://$HERO.herokuapp.com"
