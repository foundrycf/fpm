// ==========================================
// FPM: Manager Object Definition
// ==========================================
// Copyright 2012 FoundryCF
// Licensed under The MIT License
// http://opensource.org/licenses/MIT
// ==========================================
// Events:
// - install: fired when package installed
// - resolve: fired when deps resolved
// - error: fired on all errors
// - data: fired when trying to output data
// - end: fired when finished installing
// ==========================================
component name="Manager" extends="foundry.core.emitter" {
	variables.Package = require('./package');
	variables.config = require("./config");
	variables.prune = require('../util/prune');
	variables.emitter = require('emitter');
	variables.async = require('async');
	variables.console = require('console');
	variables.path = require('path');
	variables.fs = require('fs');
	variables._ = require("UnderscoreCF").init();

	public any function init(endpoints) {
		this.dependencies = {};
		this.cwd = path.dirname(GetBaseTemplatePath());
		this.endpoints = structKeyExists(arguments,'endpoints')? require("arrayObj").init(arguments.endpoints) : require("arrayObj").init();

		return this;
	}


	public any function resolve() {
	  var resolved = function() {
	    this.prune();
	    
	    this.on('install', this.emit('resolve'));
	    
	    this.install();
	  };

	  this.once('resolveLocal', function () {
	    if (this.endpoints.length()) {
	      this.once('resolveEndpoints', resolved).resolveEndpoints();
	    } else {
	      this.once('resolveFromJson', resolved).resolveFromJson();
	    }
	  });

	  this.resolveLocal();
	  return this;
	};

	public any function resolveLocal() {
		var dirs = directoryList(path='./' & config.getDirectory() & '/',listInfo="name");

		_.each(dirs,function(dir) {
			var name = path.basename(dir);
			console.log(name);

			this.dependencies[name] = [];
			this.dependencies[name].add(new Package(name, dir, this));

		});

		this.emit('resolveLocal');
	};

	public any function resolveEndpoints() {
	   // Iterate through paths
	  // Add to depedencies array
	  // Prune & install

		  async.forEach(
		  		//array
		  		this.endpoints,

		  		//iterator
				_.bind(function(endpoint, next) {
					var name = rereplacenocase(path.basename(endpoint),"(\.git)?(##.*)?$",'');
					var pkg  = new Package(name, endpoint, this);
					this.dependencies[name] = this.dependencies[name] || [];
					this.dependencies[name].add(pkg);
					pkg.on('resolve', next).resolve();
				}
				,this), 

				//callback
				_.bind(this.emit,this, 'resolveEndpoints')
			);
	};

	public any function loadJSON() {
	  var json = path.join(this.cwd, config.getjson());
	  
	  fs.exists(
	  	json,
	  	_.bind(function(exists) {
		    if (!exists) console.log('Could not find local ' & config.getJson());
		    _.bind(fs.readFile, json, 'utf8', function (err, json) {
				      if (structKeyExists(arguments,'err')) return this.emit('error', err);
				      this.json    = JSON.parse(json);
				      this.name    = this.json.name;
				      this.version = this.json.version;
				      this.emit('loadJSON');
		    	},this);
	  	},
	  	this));
	};

	public any function resolveFromJson() {
	  // loadJSON
	  // Resolve dependencies
	  // Add to dependencies array
	  // Prune & install

	  this.once('loadJSON', _.bind(function () {

	    if (!this.json.dependencies) return this.emit('error', new Error('Could not find any dependencies'));

	    async.forEach(Object.keys(this.json.dependencies), 
	    	_.bind(function (name, next) {
		      var endpoint = this.json.dependencies[name];
		      var pkg      = new Package(name, endpoint, this);
		      this.dependencies[name] = this.dependencies[name] || [];
		      this.dependencies[name].add(pkg);
		      pkg.on('resolve', next).resolve();
		    },this), 

		    _.bind(this.emit, this, 'resolveFromJson')
		   );

	  },this)).loadJSON();
	};

	public any function getDeepDependencies() {
	  var result = {};

	  for (var name in this.dependencies) {
	    this.dependencies[name].forEach(function (pkg) {
	      result[pkg.name] = result[pkg.name] || [];
	      result[pkg.name].add(pkg);
	      pkg.getDeepDependencies().forEach(function (pkg) {
	        result[pkg.name] = result[pkg.name] || [];
	        result[pkg.name].add(pkg);
	      });
	    });
	  }

	  return result;
	};

	public any function prune() {
	  try {
	    this.dependencies = prune(this.getDeepDependencies());
	  } catch (err) {
	    this.emit('error', err);
	  }
	  return this;
	};

	public any function install() {
	  async.forEach(Object.keys(this.dependencies), 
	  	_.bind(function (name, next) {
	   		this.dependencies[name][0].once('install', next).install();
	  	},this), 

	  	_.bind(this.emit, this, 'install'));
	  return this;
	};
}