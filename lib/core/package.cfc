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
	public any function init(name, endpoint, manager)  {
		//super.init();
		//variables.spawn    = require('child_process').spawn; (same as cfthread?)
		//variables.https    = require('https');
		//variables.http     = require('http'); (same as cfhttp?);
		//variables.fstream  = require('fstream'); maybe not needed?
		//variables.template = require('../util/template'); not using hogan templates
		//variables.readJSON = require('../util/read-json');
		variables.urlUtil = new foundry.core.url();
		
		//NEEDED:
		variables._        = new foundry.core.util();
		//variables.git = require("../util/git");
		variables.mkdirp   = new foundry_modules.mkdirp.mkdirp();
		variables.emitter  = new foundry.core.emitter();
		//variables.rimraf   = require('rimraf'); //not done yet
		variables.async    = new foundry_modules.async.async();
		variables.process    = new foundry.core.process();
		variables.semver = new foundry_modules.semver.semver();
		variables.path     = new foundry.core.path();
		variables.tmp      = new foundry_modules.tmp.index(); //not done yet
		variables.fs       = new foundry.core.fs();
		variables.logger = new foundry.core.console();
		variables.config   = new lib.core.config();
		variables.source   = new lib.core.source();

		this.emit = emitter.emit;
		var temp = GetTempDirectory();
		
		var home = "";

		if(server.os.name CONTAINS "windows") {
			home = process.env('USERPROFILE')
			appdata = process.env('APPDATA');
			cache = path.resolve((len(appdata) GT 0 ? appdata : temp), "foundry-cache");
		} else {
			home = process.env('HOME');
			cache = path.resolve((len(home) GT 0? home : temp), ".foundry");
		}

		this.dependencies = {};
		this.json         = {};
		this.name         = arguments.name;
		this.manager      = arguments.manager;

		this.expressions = {
			"gitPlain":new foundry.core.regexp("^(.*\.git)$"),
			"gitSemver":new foundry.core.regexp("^(.*\.git)##(.*)$"),
			"gitAdvanced":new foundry.core.regexp("^(?:(git):|git\+(https?):)\/\/([^\\]+)##?(.*)$"),
			"jscss":new foundry.core.regexp("^[\.\/~]\.?[^.]*\.(js|css)"),
			"dir":new foundry.core.regexp("^[\.\/~]"),
			"https":new foundry.core.regexp("^https?:\/\/")
		}

		this.localpath = path.join(expandPath('/'), 'foundry_modules', this.name);

		if (structKeyExists(arguments,'endpoint')) {
			if (this.expressions.gitPlain.test(endpoint)) {
				logger.print('endpoint: gitPlain');
				matches = this.expressions.gitPlain.match(endpoint);
				logger.print('matches: ' & serialize(matches));
				this.gitUrl = rereplace(matches[1],"^git\+",'');
				this.tag    = false;

			} else if (this.expressions.gitSemver.test(endpoint)) {
				logger.print('endpoint: gitSemver');
				matches = this.expressions.gitSemver.match(endpoint);
				this.tag    = matches[2];
				this.gitUrl = rereplace(matches[1],"^git\+",'');

			} else if ((this.expressions.gitAdvanced.test(endpoint))) {
				logger.print('endpoint: gitAdvanced');
				matches = this.expressions.gitAdvanced.match(endpoint);

				this.gitUrl = (structKeyExists(matches,1) || structKeyExists(matches,2)) & "://" & matches[3];
				this.tag    = matches[4];

			} else if (!_.isEmpty(semver.validRange(endpoint))) {
				logger.print('endpoint: semver');
				this.tag = endpoint;

			} else if ((this.expressions.jscss.test(endpoint) AND fileExists(endpoint))) {
				logger.print('endpoint: jscss');
				matches = this.expressions.jscss.match(endpoint);

				this.path      = path.resolve(endpoint);
				this.assetType = path.extname(endpoint);
				this.name      = replace(name,this.assetType, '');

			} else if ((this.expressions.dir.test(endpoint))) {
				logger.print('endpoint: dir');
				matches = this.expressions.dir.match(endpoint);

				this.path = path.resolve(endpoint);

			} else if ((this.expressions.https.test(endpoint))) {
				logger.print('endpoint: https');
				matches = this.expressions.https.match(endpoint);

				this.assetUrl  = endpoint;
				this.assetType = path.extname(endpoint);
				this.name      = replace(name,this.assetType, '');

			} else {
				logger.print('endpoint: other');
				//writeDump(var=endpoint,abort=true);
				this.tag = listToArray(endpoint,'##')[2];
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
	    this.once('lookup', this.clone).lookup();
	  }

	  return this;
	};

	public any function lookup() {
	  source.lookup(this.name, function (err, url) {
	    if (err) return this.emit('error', err);
	    this.gitUrl = url;
	    this.emit('lookup');
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
	  logger.print("uninstalling #this.path#");
	  
	  rimraf(this.path, function (err) {
	    if (err) return this.emit('error', err);
	    this.emit.bind(this, 'uninstall');
	  });
	};

	// Private
	public any function loadJSON() {
		//read json
		console.print("Loading Foundry.json...");
		var configFile = path.join(this.path, 'foundry.json');
		var configContent = deserializeJson(fileRead(configFile));

		var config = new foundry.core.config(configContent);
		var m = Path.resolve(Path.dirname(configFile), structKeyExists(config,'main')? config.main : '');

	    this.json    = configContent;
	    this.name    = this.json.name;
	    this.version = this.json.version;

	    this.emit('loadJSON');
	};

	public any function download() {
		logger.print("downloading #this.assetUrl#");
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

			this.once('loadJSON', this.addDependencies);
			this.loadJSON();
		});
	};

	public any function copy() {
		logger.print('copying #this.path#');

		tmp.dir(function (err, tmpPath) {
		if(!_.isEmpty(err)) {
		console.print('tmp err: ' & serialize(err));
		}

		console.print("tmp path: " & serialize(tmpPath));
		// if (this.assetType) {
		//        return fs.readFile(this.path, function (err, data) {
		//          fs.writeFile(path.join((this.path = tmpPath), 'index' + this.assetType), data, function () {
		//            this.once('loadJSON', this.addDependencies).loadJSON();
		//          });
		//        });
		//      }
		fs.copyDir(this.path,tmpPath);
		
		this.once('loadJSON', this.addDependencies);

		this.loadJSON()
		//   fs.stat(this.path, function (err, stats) {
		//     if (structKeyExists(arguments,'err') AND !_.isEmpty(err)) return this.emit('error', err);
		});
	};

	public any function getDeepDependencies(result) {
	  var result = !isNull(result)? result : [];
	  for (var name in this.dependencies) {
	    result.add(this.dependencies[name])
	    this.dependencies[name].getDeepDependencies(result);
	  }
	  return result;
	};

	public any function addDependencies() {
	  var dependencies = structKeyExists(this.json,'dependencies')? this.json.dependencies : {};

	  var tick=0;
	  
	  for(dep in dependencies) {
	  	var ep = dependencies[dep];
	  	tick++;
	  	//thread name="fpm-dep-#dep#" depname=dep endpoint=ep action="run" {
  		var logger = new foundry.core.console();
		
  		try {
		this.dependencies[dep] = new lib.core.Package(dep, ep, this);
		} catch (any err) {
			writeDump(var=err,abort=true);
		}
	  	//}
	  }

	  this.resolve();
	  // for(dep in dependencies) {
	  // 	thread name="fpm-dep-#dep#" action="join" {}
	  // }

	  //async.parallel(callbacks, this.emit.bind(this, 'resolve'));
	};

	public any function exists(callback) {
	  fs.exists(this.localPath, callback);
	};

	public any function clone() {
		logger.print('Cloning... #this.gitUrl#');

		this.path = path.resolve(cache, this.name);
		
		this.once('cache', function() {
			console.print("Caching... done.");

			this.once('loadJSON', function() {
				this.copy();
			});
			
			this.checkout();
		});

		this.cache();
	};

	public any function cache() {
		mkdirp.mkdirp(cache, function (err) {
			//if (structKeyExists(arguments,'err') AND len(arguments.err) GT 0) return this.emit('error', err);

			fs.stat(this.path, function (err) {
				// if (!structKeyExists(arguments,'err')) {
				// 	logger.print('Cached... ' & this.gitUrl);
				// 	return this.emit('cache');
				// }

				logger.print('Caching... ' & this.gitUrl)
				
				var theUrl = this.gitUrl;
				if (len(process.env("HTTP_PROXY")) GT 0) {
					theUrl = rereplace(url,"^git:", 'https:');
				}

			    try {
					//execute name="git" arguments="clone #theUrl# #this.path#" timeout="10" variable="cp";
					cp = new foundry.core.childprocess("git",["clone","#theUrl#"],{ cwd: path.dirname(this.path)});
					cp.exec();
				} catch(any err) {
					writeDump(var=err,abort=true);
					logger.print('Cloning... already exists.');
					return this.emit('error');
				}

				this.emit('cache');
			});
		});
	};

	public any function checkout() {
		logger.print('Fetching... ' & this.name);

		this.once('versions', function (versions) {
			if (arrayLen(versions) EQ 0) {
				this.emit('checkout');
				this.loadJSON();
			}

			// If tag is specified, try to satisfy it
			if (this.tag) {
				versions = versions.filter(function (version) {
					return semver.satisfies(version, this.tag);
				});

				if (arrayLen(versions) EQ 0) {
					return this.emit('error', logger.error('Can not find tag: ' & this.name & '##' & this.tag));
				}
			}

			// Use latest version
			this.tag = versions[0];

			if (this.tag) {
				logger.print("Checkout... #this.name# ## #this.tag#");

				try {
					cp = new foundry.core.childprocess("git",["checkout","-b","#this.tag#","#this.tag#"],{ 'cwd': JavaCast("string",path.resolve(cache,this.name)) });
					cp.exec();
					
				} catch(any err) {
					console.print(err.message);
					
					if (err.code EQ 128) {
						this.emit('checkout');
						this.loadJSON();
					}

					if (code NEQ 0) return this.emit('error', logger.error('Git status: ' & code));
					
					//no errors, just loadJson()
					this.emit('checkout');
					this.loadJSON();
					//var checkout = execute('git', [ 'checkout', this.tag], { cwd: this.path })
				}
			}
		});

		this.versions();
	};

	public any function describeTag() {
		cp = new foundry.core.childprocess("git",["describe","--always","--tag"],{ 'cwd': JavaCast("string",path.resolve(cache,this.name)) });
			cp.exec();

		var tag = '';

		cp.stdout.setEncoding('utf8');
		cp.stdout.on('data',  function (data) {
		tag += data;
		});

		cp.on('close', function (code) {
			if (code == 128) tag = 'unspecified'.grey; // not a git repo
			else if (code != 0) return this.emit('error', logger.error('Git status: ' + code));
			this.emit('describeTag', tag.replace("\n$", ''));
		});
	};

	public any function versions() {
		console.print("Version check...");
		
		this.on('fetch', function () {

			cp = new foundry.core.childprocess("git",["tag"],{ 'cwd': JavaCast("string",path.resolve(cache,this.name)) });
			cp.exec();

			var versions = '';

			// cp.stdout.setEncoding('utf8');
			// cp.stdout.on('data',  function (data) {
			// 	versions &= data;
			// });

			versions = versions.split("\n");
			versions = _.filter(versions,function (ver) {
				//console.print("version filter: " & serialize(ver));
				return semver.valid(ver);


				versions = versions.sort(function (a, b) {
					return semver.gt(a, b) ? -1 : 1;
				});
				this.emit('versions', this.versions);
			});
		});
	 	
	 	//go fetch! ruff ruff!
	 	this.fetch();
	};

	public any function fetch() {
		console.print("Fetch... #path.resolve(cache, this.name)#")
		//// 
		cp = new foundry.core.childprocess("git",["fetch"],{ 'cwd': path.resolve(cache,this.name) });
		cp.exec();
		//cp.close();
		// /writeDump(var=Runtime.exec(),abort=true);
	 	// try {

	 	// 	execute name="git" arguments="fetch #path.resolve(cache, this.name)#" timeout="10" variable="cp";
	 	// } catch(any err) {

	 	// }
	 	

	  // cp.on('close', function (code) {
	  //   if (code != 0) return this.emit('error', logger.error('Git status: ' + code));  
	  // });
		this.emit('fetch');
	};

	public any function fetchURL() {
	  if (this.json.repository && this.json.repository.type == 'git') {
	    this.emit('fetchURL',  this.json.repository.url);
	  } else {
	    this.emit('error', logger.error('No git url found for ' + this.json.name));
	  }
	};
}