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
		//variables.semver = createObject("java","org.semver");
		//variables.rimraf   = require('rimraf'); //not done yet
		variables.async    = new foundry_modules.async.async();
		variables.regexp    = new foundry.core.regexp();
		variables.process    = new foundry.core.process();
		variables.semver = new foundry_modules.semver.semver();
		variables.path     = new foundry.core.path();
		variables.tmp      = new foundry_modules.tmp.tmp(); //not done yet
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

		if (structKeyExists(arguments,'endpoint')) {
		  	var RegExp = new foundry.core.regexp("^(.*\.git)$");

			if (RegExp.test(endpoint)) {
				matches = RegExp.match(endpoint);
				this.gitUrl = rereplace(matches[1],"^git\+",'');
				this.tag    = false;

			} else if (RegExp.setPattern("^(.*\.git)##(.*)$").test(endpoint)) {
				matches = RegExp.match(endpoint);
				this.tag    = matches[2];
				this.gitUrl = rereplace(matches[1],"^git\+",'');

			} else if (RegExp.setPattern("^(?:(git):|git\+(https?):)\/\/([^##]+)##?(.*)$").test(endpoint)) {
				matches = RegExp.match(endpoint);

				this.gitUrl = (structKeyExists(matches,1) || structKeyExists(matches,2)) & "://" & matches[3];
				this.tag    = matches[4];

			} else if (!_.isEmpty(semver.validRange(endpoint))) {
				this.tag = endpoint;

			} else if (RegExp.setPattern("^[\.\/~]\.?[^.]*\.(js|css)").test(endpoint) AND fileExists(endpoint)) {
				matches = RegExp.match(endpoint);

				this.path      = path.resolve(endpoint);
				this.assetType = path.extname(endpoint);
				this.name      = replace(name,this.assetType, '');

			} else if (RegExp.setPattern("^[\.\/~]").test(endpoint)) {
				matches = RegExp.match(endpoint);

				this.path = path.resolve(endpoint);

			} else if (RegExp.setPattern("^https?:\/\/").test(endpoint)) {
				matches = RegExp.match(endpoint);

				this.assetUrl  = endpoint;
				this.assetType = path.extname(endpoint);
				this.name      = replace(name,this.assetType, '');

			} else {
				writeDump(var=endpoint,abort=true);
				this.tag = listToArray(endpoint,'##')[2];
			}


			if (!isNull(this.manager)) {
				this.on('data',  this.manager.emit('data'));
				this.on('error', this.manager.emit('error'));
			}
		}

		return this;
	}

	public any function resolve() {

	  if (this.assetUrl) {
	    this.download();
	  } else if (this.gitUrl) {
	    this.clone();
	  } else if (this.path) {
	    this.copy();
	  } else {
	    this.once('lookup', this.clone).lookup();
	  }

	  this.emit('resolve');

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
	  if (path.resolve(this.path) == this.localPath) return this.emit('install');
	  mkdirp(path.dirname(this.localPath), function (err) {
	    if (err) return this.emit('error', err);
	    rimraf(this.localPath, function (err) {
	      if (err) return this.emit('error', err);
	      return fs.rename(this.path, this.localPath, function (err) {
	        if (!err) return this.cleanUpLocal();
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
	public any function loadJSON(name) {
		var pathname = (structKeyExists(arguments,'name')? name : ( structKeyExists(this,'assetType') ? 'index' & this.assetType : config.getJson() ));

	  readJSON(path.join(this.path, pathname), function (err, json) {

	    if (structKeyExists(arguments,'err')) {
	      if (!name) return this.loadJSON('package.json');
	      return this.assetUrl ? this.emit('loadJSON') : this.path && this.on('describeTag', function (tag) {
	        this.version = this.tag = semver.clean(tag);
	        this.emit('loadJSON')
	      }).describeTag();
	    }
	    this.json    = json;
	    this.name    = this.json.name;
	    this.version = this.json.version;
	    this.emit('loadJSON');
	  }, this);
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
			// console.print('redirect detected #this.assetUrl#');
			// this.assetUrl = res.headers.location;
			// this.download();
			// }

			file.write(res.filecontent);

			file.close();

			this.once('loadJSON', this.addDependencies).loadJSON();

		});
	};

	public any function copy() {
		logger.print('copying #this.path#');

	  tmp.dir(function (err, tmpPath) {
	    fs.stat(this.path, function (err, stats) {
	      if (structKeyExists(arguments,'err')) return this.emit('error', err);

	      if (this.assetType) {
	        return fs.readFile(this.path, function (err, data) {
	          fs.writeFile(path.join((this.path = tmpPath), 'index' + this.assetType), data, function () {
	            this.once('loadJSON', this.addDependencies).loadJSON();
	          });
	        });
	      }

	      var reader = fstream.Reader(this.path).pipe(
	        fstream.Writer({
	          type: 'Directory',
	          path: (this.path = tmpPath)
	        })
	      );

	      this.once('loadJSON', this.addDependencies);

	      reader.on('error', this.emit('error'));
	      reader.on('end', this.loadJSON);
	    });
	  });
	};

	public any function getDeepDependencies(result) {
	  var result = result || [];
	  for (var name in this.dependencies) {
	    result.push(this.dependencies[name])
	    this.dependencies[name].getDeepDependencies(result);
	  }
	  return result;
	};

	public any function addDependencies() {
	  var dependencies = this.json.dependencies || {};
	  var callbacks    = Object.keys(dependencies).map(function (name) {
	    return function (callback) {
	      var endpoint = dependencies[name];
	      this.dependencies[name] = new Package(name, endpoint, this);
	      this.dependencies[name].once('resolve', callback).resolve();
	    };
	  });
	  async.parallel(callbacks, this.emit.bind(this, 'resolve'));
	};

	public any function exists(callback) {
	  fs.exists(this.localPath, callback);
	};

	public any function clone() {
		logger.print('cloning #this.gitUrl#');

		this.path = path.resolve(cache, this.name);

		this.once('cache', function() {
			this.once('loadJSON', this.copy)
			this.checkout();
		});

		this.cache();
	};

	public any function cache() {
		mkdirp.mkdirp(cache, function (err) {
		    if (structKeyExists(arguments,'err') AND len(arguments.err) GT 0) return this.emit('error', err);

			fs.stat(this.path, function (err) {
				if (!structKeyExists(arguments,'err')) {
					logger.print('cached ' & this.gitUrl);
					return this.emit('cache');
				}

				logger.print('caching' & this.gitUrl)
				
				var theUrl = this.gitUrl;
				if (len(process.env("HTTP_PROXY")) GT 0) {
					theUrl = rereplace(url,"^git:", 'https:');
				}

			    try {
					execute name="git" arguments="clone #theUrl# #this.path#" timeout="10" variable="cp";
					
				} catch(any err) {
					logger.print('[FOUNDRY] This package is already cloned and cached!');
					return this.emit('error');
				}

				this.emit('cache');
			});
		});
	};

	public any function checkout() {
	  logger.print('fetching' & this.name);

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
	        return this.emit('error', logger.error(
	          'Can not find tag: ' & this.name & '##' & this.tag
	        ));
	      }
	    }

	    // Use latest version
	    this.tag = versions[0];

	    if (this.tag) {
	      logger.print("checking out #this.name# ## #this.tag#");

	      execute('git', [ 'checkout', '-b', this.tag, this.tag], { cwd: this.path }).on('close', function (code) {
	        if (code == 128) {
	          return spawn('git', [ 'checkout', this.tag], { cwd: this.path }).on('close', function (code) {
	            this.emit('checkout');
	            this.loadJSON();
	          });
	        }
	        if (code != 0) return this.emit('error', logger.error('Git status: ' & code));
	        this.emit('checkout');
	        this.loadJSON();
	      });
	    }
	  }).versions();
	};

	public any function describeTag() {
	  var cp = execute('git', ['describe', '--always', '--tag'], { cwd: path.resolve(cache, this.name) });

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
	  this.on('fetch', function () {
	    var cp = spawn('git', ['tag'], { cwd: path.resolve(cache, this.name) });

	    var versions = '';

	    cp.stdout.setEncoding('utf8');
	    cp.stdout.on('data',  function (data) {
	      versions += data;
	    });

	    cp.on('close', function (code) {
	      versions = versions.split("\n");
	      versions = versions.filter(function (ver) {
	        return semver.valid(ver);
	      });
	      versions = versions.sort(function (a, b) {
	        return semver.gt(a, b) ? -1 : 1;
	      });
	      this.emit('versions', versions);
	    });
	  }).fetch();
	};

	public any function fetch() {
	  var cp = spawn('git', ['fetch'], { cwd: path.resolve(cache, this.name) });
	  cp.on('close', function (code) {
	    if (code != 0) return this.emit('error', logger.error('Git status: ' + code));
	    this.emit('fetch');
	  });
	};

	public any function fetchURL() {
	  if (this.json.repository && this.json.repository.type == 'git') {
	    this.emit('fetchURL',  this.json.repository.url);
	  } else {
	    this.emit('error', logger.error('No git url found for ' + this.json.name));
	  }
	};
}