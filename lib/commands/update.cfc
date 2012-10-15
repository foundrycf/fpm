// ==========================================
// FPM: update API
// ==========================================
// Copyright 2012 FoundryCF
// Licensed under The MIT License
// http://opensource.org/licenses/MIT
// ==========================================
// 1. Recursively resolve dependencies
// 2. Intelligently work out which deps to
//    use (versioning)
// 3. Throw if deps conflict
// ==========================================
component name="update" extends="foundry.core" {
	public any function init() {
		return this;
	}

	public any function update(args = [], options = {}) {
		var emitter = require('emitter');
		var installer = require('./install');
		var install = installer.install;
		//var async   = require('async');
		//var nopt    = require('nopt');
		var manager = new fpm.lib.core.manager(args);

		manager.resolveLocal();
		
		var packages = {};

	    _.each(manager.dependencies, function (value, name) {
	    	packages[name] = value[1];
	    });

	    var urls = _.map(_.values(packages), function (pkg) {
			pkg.loadJSON();
			theUrl = pkg.fetchURL();
			return theUrl;
	    });

	    
		var installURLS = function (err, urls) {
			var installEmitter = install(urls);
			// installEmitter.on('data',  emitter.emit.bind(emitter, 'data'));
			// installEmitter.on('error', emitter.emit.bind(emitter, 'error'));
			// installEmitter.on('end',   emitter.emit.bind(emitter, 'end'));
		};
		//if (structKeyExists(arguments,'options') && structKeyExists(arguments.options,'save')) save(emitter, manager, paths);

		//manager.resolve();

		return emitter;
	};

	public any function line(argv) {
		var options  = nopt(optionTypes, shorthand, argv);
		var paths    = options.argv.remain.slice(1);

		if (options.help) return help('install');
		return module.exports(paths, options);
	}
}