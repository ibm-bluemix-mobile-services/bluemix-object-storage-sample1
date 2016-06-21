var express = require('express');
var cfenv = require('cfenv');
var log4js = require('log4js');
var jsonParser = require('body-parser').json();
var request = require('superagent');
var Q = require('q');

// Using hardcoded user repository

var appEnv = cfenv.getAppEnv();
var credentials = appEnv.getServiceCreds('<object-storage-instance>');
var objectStorageProjectId = credentials['projectId'];
var objectStorageUserId = credentials['userId'];
var objectStoragePassword = credentials['password'];

var userRepository = {
	"<mca-username>": { password:"<mca-password>", displayName:"", dob:""}
}

var challengeJson = {
	status: "challenge",
	challenge: {
		text: "Enter username and password"
	}
};

var app = express();
var logger = log4js.getLogger("CustomIdentityProviderApp");
logger.info("Starting up");


app.post('/apps/:tenantId/:realmName/startAuthorization', jsonParser, function(req, res){

	var tenantId = req.params.tenantId;
	var realmName = req.params.realmName;
	var headers = req.body.headers;

	logger.debug("startAuthorization", tenantId, realmName, headers);

	res.status(200).json(challengeJson);
});

app.post('/apps/:tenantId/:realmName/handleChallengeAnswer', jsonParser, function(req, res){

	var tenantId = req.params.tenantId;
	var realmName = req.params.realmName;
	var challengeAnswer = req.body.challengeAnswer;

	logger.debug("handleChallengeAnswer", tenantId, realmName, challengeAnswer);

	var username = req.body.challengeAnswer["username"];
	var password = req.body.challengeAnswer["password"];

	var userObject = userRepository[username];

	if (userObject && userObject.password == password ){
		logger.debug("Login success for userId ::", username);

		getToken(userObject).then(function(data) {
			var responseJson = {
				status: "success",
				userIdentity: {
					userName: username,
					displayName: userObject.displayName,
					attributes: {
						token: data.headers["x-subject-token"],
						dob: userObject.dob
					}
				}
			};

			res.status(200).json(responseJson);

		}).catch(function(err) {
			logger.debug("Error received while fetching token for object storage");
			res.status(200).json(challengeJson);
		});

	} else {
		logger.debug("Login failure for userId ::", username);
		res.status(200).json(challengeJson);
	}
});

app.use(function(req, res, next){
	res.status(404).send("This is not the URL you're looking for");
});

var getToken = function(userObject) {

	var payload = {
	    auth: {
	        identity: {
	            methods: [
	                "password"
	            ],
	            password: {
	                user: {
	                    id: objectStorageUserId,
	                    password: objectStoragePassword
	                }
	            }
	        },
	        scope: {
	            project: {
	                id: objectStorageProjectId
	            }
	        }
	    }
	};

	var deferred = Q.defer();

	request
		.post("https://identity.open.softlayer.com/v3/auth/tokens")
		.set('Accept', 'application/json')
		.send(payload)
		.end(function(err, data) {

			if (err) {
				logger.debug("Error received while fetching token for object storage");
				deferred.reject(err);
			}

			deferred.resolve(data);
		});

	return deferred.promise;
}

var server = app.listen(cfenv.getAppEnv().port, function () {
	var host = server.address().address;
	var port = server.address().port;
	logger.info('Server listening at %s:%s', host, port);
});
