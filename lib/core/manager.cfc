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
component name="manager" extends="foundry.lib.module" {
	public any function init(array endpoints) {
		variables.outputMode = "console";
		variables.config = require("./config");
		variables.prune = require('../util/prune');
		variables.futil	= createObject("java","org.apache.commons.io.FileUtils"); //not done yet
		var jarPaths = [];
		jarPaths.add(expandPath('/fpm/deps/wildcard-1.0.jar'));
		variables.loader = createObject("component","foundry.deps.javaloader.JavaLoader").init(jarPaths);
		
		mixin("emitter");
		this.emitter_init();
		//variables.async = require('async');
		variables.console = require('console');
		variables.path = require('path');
		variables.fs = require('fs');
		variables._ = require("util");

		this.json = {
			'dependencies':{}
		};

		this.dependencies = {};
		this.cwd = request.cwd;
		this.endpoints = structKeyExists(arguments,'endpoints')? arguments.endpoints : [];

		return this;
	}


	public any function resolve() {
		var resolved = function() {
			this.prune();
			this.install();

			//this.emit('resolve');
		};

		this.resolveLocal();

		if (arrayLen(this.endpoints)) {
			this.resolveEndpoints();
			resolved();
		} else {
			this.resolveFromJson();
			resolved();
		}

		return this;
	};

	public any function resolveLocal() {
		variables.dirs = loader.create("com.esotericsoftware.wildcard.Paths").init(javaCast("string",this.cwd),['./foundry_modules/*']).dirsOnly().getPaths();
		_.each(dirs,function(dir) {
			var name = path.basename(dir);
			
			this.dependencies[name] = [];
			this.dependencies[name].add(new Package(name, dir, this));

		},this);

		//this.emit('resolveLocal');
	};

	public any function resolveEndpoints() {
		// Iterate through paths
		// Add to depedencies array
		// Prune & install
		var endpoints = this.endpoints;

		for(ep in endpoints) {
			var name = rereplacenocase(path.basename(ep),"(\.git)?(##.*)?$",'');
			var pkg  = new Package(name, ep, this);
				this.dependencies[name] = structKeyExists(this.dependencies,name)? this.dependencies[name] : [];
				this.dependencies[name].add(pkg);
				pkg.resolve();
		}

		//this.emit('resolveEndpoints');
	};

	public any function loadJSON() {
		var json = path.join(this.cwd, config.getjson());
		//print('config',json);
		
		if(fileExists(json)) {
			var jsonFile = fileRead(json,'utf8');
			//if (structKeyExists(arguments,'err')) return this.emit('error', err);
			this.json    = deserializeJson(jsonFile);
			this.name    = this.json.name;
			this.version = this.json.version;
		} else {
			print('error','Could not find a foundry.json in your project.');
		}
	};

	public any function resolveFromJson() {
	  // loadJSON
	  // Resolve dependencies
	  // Add to dependencies array
	  // Prune & install
		this.loadJSON();
	 
	    if (structCount(this.json.dependencies) LTE 0) return print('error','Could not find any dependencies');

	    _.forEach(structKeyArray(this.json.dependencies),function (name) {
		      var endpoint = this.json.dependencies[name];
		      var pkg      = new Package(name, endpoint, this);
		      this.dependencies[name] = structKeyExists(this.dependencies,name)? this.dependencies[name] : [];
		      this.dependencies[name].add(pkg);
		      pkg.resolve();
		  },this);
	};

	public any function getDeepDependencies() {
	  var result = {};

	  for (name in structKeyArray(this.dependencies)) {
	    _.forEach(this.dependencies[name],function (pkg) {
	      result[pkg.name] = structKeyExists(result,pkg.name)? result[pkg.name] : [];
	      result[pkg.name].add(pkg);
	      _.forEach(pkg.getDeepDependencies(),function (pkg) {
	        result[pkg.name] = result[pkg.name] || [];
	        result[pkg.name].add(pkg);
	      });
	    });
	  };
	  return result;
	};

	public any function prune() {
		// try {
		// 	this.dependencies = this.prune(this.getDeepDependencies());
		// } catch (err) {
		// 	print("error",err.message);
		// 	//this.emit('error', err);
		// }

		return this;
	};

	public any function install() {
		_.forEach(structKeyArray(this.dependencies),function (name) {
	   			this.dependencies[name][1].install();
	  		},
	  		this
	  	); 

		//this.emit('install');

	  return this;
	};

	include "../util/print_func.cfm";
}