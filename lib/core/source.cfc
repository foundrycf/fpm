// ==========================================
// FPM: Source Api
// ==========================================
// Copyright 2012 FoundryCF
// Licensed under The MIT License
// http://opensource.org/licenses/MIT
// ==========================================
component extends="foundry.core" {
	public any function init(outputMode = "html") {
		variables.process = require("process");
		variables._        = require('util');
		variables.console = require("console");
		variables.outputMode = arguments.outputMode;
		variables.endpoint = 'http://fpm.herokuapp.com/packages';
	}

	public any function lookup(name,callback) {
		var errors = {};
		try {
			var req = new http(method="get",url=endpoint & '/' & encodeURIComponent(name));
			var res = req.send().getPrefix();
		} catch (any err) {
			errors = err;
			return callback(errors,'');
		}
		
	    if (res.status_code NEQ 200) return callback(errors,name & ' not found');
	    callback(errors,deserializeJson(res.filecontent).url);
	};

	public any function register(name, url, callback = function() {}) {
		try {
			var body = {name: name, url: url};
			var req = new http(method="post",url=endpoint);
			req.addParam(type="formfield",name="name",value="#arguments.name#"); 
			req.addParam(type="formfield",name="url",value="#arguments.url#"); 
			var res = req.send().getPrefix();
		} catch (any err) {
			if(!isNull(err)) {
				print('error',err.Detail);
			 	return callback(err.Detail);
			}
		}
		if (res.status_code EQ 406) {
			print('error','Duplicate package');
			return callback('Duplicate package');
		}

		if (res.status_code EQ 400) {
			print('error','Incorrect format');
			return callback('Incorrect format');
		}

		if (res.status_code NEQ 201) {
			print('error','Unknown error: ' & res.status_code);
			return callback('Unknown error: ' & res.status_code);
		}
		

		callback();
	};

	public any function search(name, callback) {
		var errors = {};
		try {
			var req = new http(method="get",url=endpoint & '/search/' & encodeURIComponent(name));
			var res = req.send().getPrefix();
		} catch (any err) {
			errors = err;
		 	return callback(errors);
		}

	  	callback(errors,deserializeJson(res.filecontent));
	};

	public any function info(name, callback) {
		var errors = {};
		lookup(name, function (err, path) {
			if (structCount(err) GT 0) return callback(err);

			var pkg = new lib.core.package(name,path);
			//var pkg     = new Package(name, url);

			pkg.resolve();
			pkg.version_check();

			callback(errors, { pkg: pkg, versions: pkg.versions });
		});
	};

	public any function all(callback) {
		var errors = {};
		try {
			var req = new http(method="get",url=endpoint);
			var res = req.send().getPrefix();
		} catch (any err) {
			errors = err;
		 	return callback(errors,[]);
		}

	  	callback(errors,deserializeJson(res.filecontent));
	};

	private any function encodeURIComponent(stringToEncode) {
		variables.encodedString = arguments.stringToEncode;
		variables.encodedString = replace( variables.encodedString, "!", "%21", "all" );
		variables.encodedString = replace( variables.encodedString, "*", "%2A", "all" );
		variables.encodedString = replace( variables.encodedString, "##", "%23", "all" );
		variables.encodedString = replace( variables.encodedString, "$", "%24", "all" );
		variables.encodedString = replace( variables.encodedString, "%", "%25", "all" );
		variables.encodedString = replace( variables.encodedString, "&", "%26", "all" );
		variables.encodedString = replace( variables.encodedString, "'", "%27", "all" );
		variables.encodedString = replace( variables.encodedString, "(", "%28", "all" );
		variables.encodedString = replace( variables.encodedString, ")", "%29", "all" );
		variables.encodedString = replace( variables.encodedString, "@", "%40", "all" );
		variables.encodedString = replace( variables.encodedString, "/", "%2F", "all" );
		variables.encodedString = replace( variables.encodedString, "^", "%5E", "all" );
		variables.encodedString = replace( variables.encodedString, "~", "%7E", "all" );
		variables.encodedString = replace( variables.encodedString, "{", "%7B", "all" );
		variables.encodedString = replace( variables.encodedString, "}", "%7D", "all" );
		variables.encodedString = replace( variables.encodedString, "[", "%5B", "all" );
		variables.encodedString = replace( variables.encodedString, "]", "%5D", "all" );
		variables.encodedString = replace( variables.encodedString, "=", "%3D", "all" );
		variables.encodedString = replace( variables.encodedString, ":", "%3A", "all" );
		variables.encodedString = replace( variables.encodedString, ",", "%2C", "all" );
		variables.encodedString = replace( variables.encodedString, ";", "%3B", "all" );
		variables.encodedString = replace( variables.encodedString, "?", "%3F", "all" );
		variables.encodedString = replace( variables.encodedString, "+", "%2B", "all" );
		variables.encodedString = replace( variables.encodedString, "\", "%5C", "all" );
		variables.encodedString = replace( variables.encodedString, '"', "%22", "all" );
		return variables.encodedString;
	}

	public any function print(action = "",detail = "") {
		switch (outputMode) {
			case "html":
				if(action EQ "error") {
					writeOutput('<div class="fpm-output-line"><strong>fpm</strong> <span style="color:red;">#action#</span> #detail#</div>');
				} else {
					writeOutput('<div class="fpm-output-line"><strong>fpm</strong> <span style="color:navy;">#action#</span> #detail#</div>');
				}
				//flush.flush();
				break;
			case "console":
				if(action EQ "error") {
					console.print("@|bold,black fpm|@ @|bold,red error|@ @|black #detail#|@");
				} else {
					console.print("@|bold,black fpm|@ @|bold,cyan #action#|@ @|black #detail#|@");
				}
				break;

			default:
				writeOutput("fpm #action# #detail#");
		}
	}
}

