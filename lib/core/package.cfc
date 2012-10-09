// ==========================================
// FPM: Package Object Definition
// ==========================================
// Copyright 2012 FoundryCF
// Licensed under The MIT License
// http://opensource.org/licenses/MIT
// ==========================================
// Events:
//  - install: fired when package installed
//  - resolve: fired when deps resolved
//  - error: fired on all errors
//  - data: fired when trying to output data
// ==========================================
component name="package" extends="foundry.core.emitter" {
	

	public any function init(name, endpoint, manager, output = "html")  {
		//NEEDED:
		variables._ 		= require("util");
		//variables.git 	= require("../util/git");
		variables.mkdirp	= require("mkdirp");
		//variables.rimraf	= require('rimraf'); //not done yet
		//variables.async		= require("async");
		variables.process	= require("process");
		variables.semver	= require("semver");
		variables.path		= require("path");
		variables.tmp 		= require("tmp");
		variables.fs		= require("fs");
		variables.console 	= require("console");
		variables.childprocess = require("childprocess");
		variables.urlUtil = require("url");
		//variables.flush = require("../../deps/scriptcfc/flush");
		variables.config   = new lib.core.config();
		variables.source   = new lib.core.source();

		variables.outputMode = arguments.output;
		var temp = GetTempDirectory();
		
		var home = "";

		if(server.os.name CONTAINS "windows") {
			home = process.env('USERPROFILE');
			appdata = process.env('APPDATA');
			cache = path.resolve((len(appdata) GT 0 ? appdata : temp), "foundry-cache");
		} else {
			home = process.env('HOME');
			cache = path.resolve((len(home) GT 0? home : temp), ".foundry");
		}

		this.dependencies = {};
		this.json         = {};
		this.name         = arguments.name;
		if(structKeyExists(arguments,'manager')) {
		this.manager      = arguments.manager;
		}

		this.expressions = {
			"gitPlain":require("regexp","^(.*\.git)$"),
			"gitSemver":require("regexp","^(.*\.git)##(.*)$"),
			"gitAdvanced":require("regexp","^(?:(git):|git\+(https?):)\/\/([^\\]+)##?(.*)$"),
			"jscss":require("regexp","^[\.\/~]\.?[^.]*\.(js|css)"),
			"dir":require("regexp","^[\.\/~]"),
			"https":require("regexp","^https?:\/\/")
		};

		this.localpath = path.join(expandPath('/'), 'foundry_modules', this.name);

		if (structKeyExists(arguments,'endpoint')) {
			if (this.expressions.gitPlain.test(endpoint)) {
				//logger.print('endpoint: gitPlain');
				matches = this.expressions.gitPlain.match(endpoint);
				//logger.print('matches: ' & serializeJson(matches));
				this.gitUrl = rereplace(matches[1],"^git\+",'');
				this.tag    = false;

			} else if (this.expressions.gitSemver.test(endpoint)) {
				//logger.print('endpoint: gitSemver');
				matches = this.expressions.gitSemver.match(endpoint);
				this.tag    = matches[2];
				this.gitUrl = rereplace(matches[1],"^git\+",'');

			} else if ((this.expressions.gitAdvanced.test(endpoint))) {
				//logger.print('endpoint: gitAdvanced');
				matches = this.expressions.gitAdvanced.match(endpoint);

				this.gitUrl = (structKeyExists(matches,1) || structKeyExists(matches,2)) & "://" & matches[3];
				this.tag    = matches[4];

			} else if (!_.isEmpty(semver.validRange(endpoint))) {
				//logger.print('endpoint: semver');
				this.tag = endpoint;

			} else if ((this.expressions.jscss.test(endpoint) AND fileExists(endpoint))) {
				//logger.print('endpoint: jscss');
				matches = this.expressions.jscss.match(endpoint);

				this.path      = path.resolve(endpoint);
				this.assetType = path.extname(endpoint);
				this.name      = replace(name,this.assetType, '');

			} else if ((this.expressions.dir.test(endpoint))) {
				//logger.print('endpoint: dir');
				matches = this.expressions.dir.match(endpoint);

				this.path = path.resolve(endpoint);

			} else if ((this.expressions.https.test(endpoint))) {
				//logger.print('endpoint: https');
				matches = this.expressions.https.match(endpoint);

				this.assetUrl  = endpoint;
				this.assetType = path.extname(endpoint);
				this.name      = replace(name,this.assetType, '');

			} else {
				//logger.print('endpoint: other');
				//writeDump(var=endpoint,abort=true);
				if(listLen(endpoint,'##') GT 1) {
					this.tag = listToArray(endpoint,'##')[2];
				}
			}


			if (!isNull(this.manager)) {
				// this.on('data',  this.manager.emit('data'));
				// this.on('error', this.manager.emit('error'));
			}
		}

		return this;
	}

	public any function resolve() {
	  if (isDefined("this.assetUrl")) {
	    this.download();
	  } else if (isDefined("this.gitUrl")) {
	    this.clone();
	  } else if (isDefined("this.path")) {
	    this.copy();
	  } else {
	    this.lookup();
	    this.clone();
	  }

	  return this;
	};

	public any function lookup() {
	  source.lookup(this.name, function (err, url) {
	    if (err) return print("error", err.message);
	    this.gitUrl = url;
	    //this.emit('lookup');
	  });
	};

	public any function install() {
		//if (path.resolve(this.path) == this.localPath) return this.emit('install');
	  mkdirp.mkdirp(path.dirname(this.localPath), function (err) {
	    if (structKeyExists(arguments,'err')) return this.emit('error', err);
	    rimraf(this.localPath, function (err) {
	      if (structKeyExists(arguments,'err')) return this.emit('error', err);
	      return fs.rename(this.path, this.localPath, function (err) {
	        if (!structKeyExists(arguments,'err')) return this.cleanUpLocal();
	        fstream.Reader(this.path)
	          .on('error', this.emit.bind(this, 'error'))
	          .on('end', rimraf.bind(this, this.path, this.cleanUpLocal))
	          .pipe(
	            fstream.Writer({
	              type: 'Directory',
	              path: this.localPath
	            })
	          );
	      });
	    });
	  });
	};
	public any function cleanUpLocal() {
	  if (this.gitUrl) this.json.repository = { type: "git", url: this.gitUrl };
	  if (this.assetUrl) this.json = this.generateAssetJSON();
	  fs.writeFile(path.join(this.localPath, config.getJson()), JSON.stringify(this.json, null, 2));
	  rimraf(path.join(this.localPath, '.git'), this.emit.bind(this, 'install'));
	};

	public any function generateAssetJSON() {
	  var semverParser = new RegExp('(' & semver.expressions.parse.toString().replace("\$?\/\^?", '') & ')');
	  return {
	    name: this.name,
	    main: 'index' & this.assetType,
	    version: semverParser.match(this.assetUrl) ? matches[1] : "0.0.0",
	    repository: { type: "asset", url: this.assetUrl }
	  };
	};

	public any function uninstall() {
	  print("uninstalling",this.path);
	  
	  rimraf(this.path, function (err) {
	    
	  });
	};

	// Private
	public any function loadJSON() {
		
		//read json
		//print("reading",path.join(this.path, 'foundry.json'));
		var configFile = path.join(this.path, 'foundry.json');
		var configFileRead = "";
		var configData = {};
		//print("configPath -> #configFile#");
		if(fileExists(configFile)) {
			configFileRead = fileRead(configFile);
			configData = deserializeJson(configFileRead);
		} else {
			print('error','No foundry.json found. Failed to get info.');
			return;
		}

		//print("configContent -> #serializeJson(configFile)#");

		var config = new foundry.core.config(configData);
		var m = Path.resolve(Path.dirname(configFile), structKeyExists(config,'main')? config.main : '');

		//print("main path -> #m#");
	    this.json    = configData;
	    this.name    = this.json.name;
	    this.version = this.json.version;

		//print("[END] LOAD JSON");
	};

	public any function download() {
		print("downloading",this.assetUrl);
		var src  = urlUtil.parse(this.assetUrl);
		var req  = new http();
		req.setUrl(this.assetUrl);
		req.setgetAsBinary(true);

		if (len(process.env("HTTP_PROXY")) GT 0) {
			src = urlUtil.parse(process.env("HTTP_PROXY"));
			src.path = this.assetUrl;
		}

		tmp.dir(function (err, tmpPath) {
			this.path = tmpPath;
		    var file = fs.createWriteStream(path.join(this.path, 'index' & this.assetType));


	    	var res = req.send().getPrefix();
	    	
	    	//NOT APPLICABLE BECAUSE: cfhttp() automatically redirects up to 4 times 
			//if assetUrl results in a redirect we update the assetUrl to the redirect to url
			// if (res.statusCode > 300 && res.statusCode < 400 && res.headers.location) {
			// logger.print('redirect detected #this.assetUrl#');
			// this.assetUrl = res.headers.location;
			// this.download();
			// }

			file.write(res.filecontent);

			file.close();

			this.loadJSON();
			this.addDependencies();
		});
	};

	public any function copy() {

		print('copying',this.path);

		tmp.dir(function (err, tmpPath) {
			// if (this.assetType) {
			//        return fs.readFile(this.path, function (err, data) {
			//          fs.writeFile(path.join((this.path = tmpPath), 'index' + this.assetType), data, function () {
			//            this.once('loadJSON', this.addDependencies).loadJSON();
			//          });
			//        });
			//      }
			fs.copyDir(this.path,tmpPath);
		
			this.loadJSON();
			this.addDependencies();
			//   fs.stat(this.path, function (err, stats) {
			//     if (structKeyExists(arguments,'err') AND !_.isEmpty(err)) return this.emit('error', err);
		});
	};

	public any function getDeepDependencies(result) {
	  var res = !isNull(result)? result : [];
	  for (var name in this.dependencies) {
	    res.add(this.dependencies[name]);
	    this.dependencies[name].getDeepDependencies(res);
	  }
	  return res;
	};

	public any function addDependencies() {
	  var dependencies = structKeyExists(this.json,'dependencies')? this.json.dependencies : {};

	  for(dep in dependencies) {
	  	var ep = dependencies[dep];
  		this.dependencies[dep] = new lib.core.Package(dep, ep);

  		this.dependencies[dep].resolve();
	  }

		//writeDump(var=this,abort=true);
	  //this.resolve();
	  // for(dep in dependencies) {
	  // 	thread name="fpm-dep-#dep#" action="join" {}
	  // }

	  //async.parallel(callbacks, this.emit.bind(this, 'resolve'));
	};

	public any function exists(callback) {
	  fs.exists(this.localPath, callback);
	};

	public any function clone() {
		this.path = path.resolve(cache, this.name);
		this.cache();
		this.checkout();
		this.copy();
	};

	public any function cache() {
		mkdirp.mkdirp(cache, function (err) {
			//if (structKeyExists(arguments,'err') AND len(arguments.err) GT 0) return this.emit('error', err);

			fs.stat(this.path, function (err) {
				// if (!structKeyExists(arguments,'err')) {
				// 	logger.print('Cached... ' & this.gitUrl);
				// 	return this.emit('cache');
				// }
				if(!isDefined("this.giturl")) {
					//writeDump(var=this,abort=true);
					print("error","No git url specified for #this.name#");
					return;
				}
				print('caching',this.gitUrl);

				var theUrl = this.gitUrl;
				
				if (len(process.env("HTTP_PROXY")) GT 0) {
					theUrl = rereplace(url,"^git:", 'https:');
				}

				//execute name="git" arguments="clone #theUrl# #this.path#" timeout="10" variable="cp";
				cp = childprocess.spawn("git",["clone","#theUrl#"],{ cwd: path.dirname(this.path)});
			

				//this.emit('cache');
			});
		});
	};

	public any function checkout() {
		print('fetching',this.name);
		cp = childprocess.spawn("git",["checkout"],{ 'cwd': JavaCast("string",path.resolve(cache,this.name)) });
		//this.version_check();

		// if (arrayLen(this.versions) EQ 0) {
		// 	this.loadJSON();
		// 	return;
		// }

		// // If tag is specified, try to satisfy it
		// if (this.tag) {
		// 	this.versions = _.filter(this.versions,function (version) {
		// 		return semver.satisfies(version, this.tag);
		// 	});

		// 	if (arrayLen(versions) EQ 0) {
		// 		return print('error','Can not find tag: ' & this.name & '##' & this.tag);
		// 	}
		// }

		// // Use latest version
		// this.tag = this.versions[1];

		// if (this.tag) {
		// 	print("checking out","#this.name# ## #this.tag#");

		// 	try {
		// 		
				
				
		// 	} catch(any err) {
		// 		console.print(err.message);
				
				
		// 		// if (err.code EQ 128) {
		// 		//	this.loadJSON();
		// 		// }

		// 		if (code NEQ 0) return print('error',err.message);
				
		// 		//no errors, just loadJson()
		// 		this.loadJSON();
		// 		//var checkout = execute('git', [ 'checkout', this.tag], { cwd: this.path })
		// 		cp = childprocess.spawn("git",["checkout","-b","#this.tag#","#this.tag#"],{ 'cwd': JavaCast("string",path.resolve(cache,this.name)) });
				
		// 	}
		// }

	};

	public any function describeTag() {
		cp = childprocess.spawn("git",["describe","--always","--tag"],{ 'cwd': JavaCast("string",path.resolve(cache,this.name)) });
		

		var tag = '';

		cp.stdout.setEncoding('utf8');
		cp.stdout.on('data',  function (data) {
			tag += data;
		});

		// cp.on('close', function(code) {
		// 	if (code == 128) tag = 'unspecified'.grey; // not a git repo
		// 	else if (code != 0) return this.emit('error', logger.error('Git status: ' + code));
		// 	this.emit('describeTag', tag.replace("\n$", ''));
		// });
	};

	public any function version_check() {
		print("version check",this.name);

	 	//go fetch! ruff ruff!
	 	this.fetch();
		cp = childprocess.spawn("git",["tag"],{ 'cwd': JavaCast("string",path.resolve(cache,this.name)) });
		

		var versions = "";

		versions &= cp.stdout;

		versions = versions.split("\n");
		versions = _.filter(versions,function (ver) {
			return _.isString(semver.valid(ver));
			versions = _.sort(versions,function (a, b) {
				return semver._gt(a, b) ? -1 : 1;
			});
		});

		this.versions = versions;
	};

	public any function fetch() {
		print("fetch",path.resolve(cache, this.name));
		cp = childprocess.spawn("git",["fetch"],{ 'cwd': path.resolve(cache,this.name) });
		
		//cp.close();
		// /writeDump(var=Runtime.exec(),abort=true);
	 	// try {

	 	// 	execute name="git" arguments="fetch #path.resolve(cache, this.name)#" timeout="10" variable="cp";
	 	// } catch(any err) {

	 	// }
	 	

	  // cp.on('close', function (code) {
	  //   if (code != 0) return this.emit('error', logger.error('Git status: ' + code));  
	  // });
	};

	public any function fetchURL() {
	  if (this.json.repository && this.json.repository.type == 'git') {
	    //this.emit('fetchURL',  this.json.repository.url);
	  } else {
	    print('error','No git url found for ' & this.json.name);
	  }
	};

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