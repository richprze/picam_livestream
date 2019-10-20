import bcrypt

user = input("Username: ")
pswd1 = input("Password: ")
pswd2 = input("Password again: ")
if pswd1 == pswd2:
    with open("pass.user", 'w') as f:
        hashed = bcrypt.hashpw(pswd1.encode('ascii'), bcrypt.gensalt(12))
        f.write(user.lower() + " " + str(hashed, 'utf-8'))
    print("User: {}, pass: {}, hashed: {}".format(user.lower(), pswd1, hashed))
else:
    print("ERROR: passwords did not match. Try again.")
