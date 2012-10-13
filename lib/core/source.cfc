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
		print('looking for',name);
		try {
			var req = new http(method="get",url=endpoint & '/' & encodeURIComponent(name));
			var res = req.send().getPrefix();
		} catch (any err) {
			errors = err;
			print('error',errors.message);
			
			return callback(errors.message,'');
		}

	    if (res.responseheader.status_code NEQ 200) {
			print('error',name & ' not found');
			return callback(errors,name & ' not found');
	    }
	    pkgInfo = deserializeJson(res.filecontent);
		print('found package',name & " (" & pkgInfo.url & ")");
	    callback(errors,deserializeJson(res.filecontent).url);
	};

	noop = function() {};

	public any function register(name, theUrl, callback = noop) {
		
		print('registering',name);
		
		try {
			var req = new http(method="post",url=endpoint);
			req.addParam(type="formfield",name="name",value="#arguments.name#"); 
			req.addParam(type="formfield",name="url",value="#arguments.theUrl#"); 
			var res = req.send().getPrefix();
		} catch (any err) {
			if(!isNull(err)) {
				print('error',err.message);
			 	return callback(err.additional);
			}
		}
		if (res.responseheader.status_code EQ 406) {
			print('error','Failed to register package: A package already exists with this information.');
			return callback('Failed to register package: A package already exists with this information.');
		}

		if (res.responseheader.status_code EQ 400) {
			print('error','Failed to register package: The package was in an unacceptable format for the registry.');
			return callback('Failed to register package: The package was in an unacceptable format for the registry.');
		}

		if (res.responseheader.status_code NEQ 201) {
			print('error','Failed to register package: Unknown response: ' & res.responseheader.status_code);
			return callback('Failed to register package: Unknown response: ' & res.responseheader.status_code);
		}
		
		print('registered',name);
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

	include "../util/print_func.cfm";
}

