var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var cookieSession = require('cookie-session');
var fs = require('fs');
var WebSocket = require('ws');
const bcrypt = require('bcrypt');

// TODO: get stream secret from consule var
var STREAM_SECRET = process.env.SECRET;
var STREAM_PORT = process.env.PORT || 3000;
var WEBSOCKET_PORT = process.env.PORT || 3001;
var TOKEN = ''

// generate a secret token for cookie session
require('crypto').randomBytes(24, function(err, buffer) {
	TOKEN = buffer.toString('hex');
});

var app = express();

app.use(cookieSession({
	name: 'session',
	maxAge: 1000*60*60*24*30,
	keys: [TOKEN]
}))

app.use(express.static('public'))
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

app.set('view engine', 'ejs');

// Auth function used for client access
var auth = function(req, res, next) {
	console.log(req.session);
	if (!req.session.loggedin) {
		// Instead redirect to login page
		res.redirect('/login');
	} else {
		req.session.nowInMinutes = Math.floor(Date.now() / 60e3)
		next();
	}
};

// verify function used for WSS
var verify = function(info) {
	console.log("verify called");
	if (info.req.url.replace("/","") === STREAM_SECRET) {
		console.log("verified");
		return true;
	} else {
		console.log("NOT verified");
		return false;
	}
};


app.get('/', auth, function (req, res) {
	// home page is the main page to view video
	console.log("home page");
	res.render('index', { secret: STREAM_SECRET });
})

app.get('/login', function (req, res) {
	// login form
	console.log(req.query.error);
	if (req.query.error) { 
		var err = true;
	} else {
		var err = false;
	}
	res.render('login', { error: err });
})

app.get('/logout', function (req, res) {
	if (req.session.loggedin) {
		req.session.loggedin = false;
	}
	res.redirect('/');
});

app.post('/login', function (req, res) {
	// use login data to verify and login
	console.log('post to login');
	var user = req.body.username.toLowerCase();
	var hash = process.env[user];
	if (hash) {
		bcrypt.compare(req.body.password, hash, function(e, r) {
			if (r) {
				console.log("SUCCESSFUL LOGIN. password matches");
				req.session.loggedin = true;
				// TODO: set cookie experiation date
				// redirect to home
				res.redirect('/');
			} else {
				console.log("INCORRECT PASSWORD. password does not match");
				res.redirect('/login?error=true');
			}
		});
	} else {
		// return error
		console.log('INCORRECT USERNAME. username file not found');
		return res.redirect('/login?error=true');
	}
});

app.post('/'+STREAM_SECRET, function (req, res) {
	console.log("Posting stream. Connected: " + 
			req.socket.remoteAddress + ':' +
			req.socket.remotePort
	);
	req.on('data', function(data) {
		wss.broadcast(data);
	});
	req.on('end', function() {
		console.log('Stream: request.on(end) called');
	});
});


app.set('port', process.env.PORT || 3000);
app.set('ipaddr', '0.0.0.0');

var http_server = app.listen(app.get('port'), app.get('ipaddr'), function() {
  console.log('Express server listening on port ' + http_server.address().port);
});

var wss = new WebSocket.Server({server: http_server, perMessageDeflate: false, verifyClient: verify});
// var wss = new WebSocket.Server({port: WEBSOCKET_PORT, perMessageDeflate: false, verifyClient: verify});
wss.connectionCount = 0;
wss.on('connection', function(socket) {
	wss.connectionCount++;
	console.log(
		'New WebSocket Connection: ',
		'('+wss.connectionCount+' total)'
	);
	socket.on('message', function incoming(msg) {
		console.log('Recieved WS msg: ' + msg);
	});
	socket.on('close', function(code, message){
		wss.connectionCount--;
		console.log(
			'Disconnected WebSocket ('+wss.connectionCount+' total)'
		);
	});
});

wss.broadcast = function(data) {
	wss.clients.forEach(function each(client) {
		if (client.readyState === WebSocket.OPEN) {
			client.send(data);
		}
	});
};

