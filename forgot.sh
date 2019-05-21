echo "create a username and password for your website."
echo "enter a username and password, twice:"
python3 hash_pass.py

echo "set the username and hashed password as a heroku config variable"
read USER PASS <<< $(cat pass.user | awk '{ print $1, $2}')
cd heroku
heroku config:set $USER=$PASS
