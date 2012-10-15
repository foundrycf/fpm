// ==========================================
// FPM: uninstall API
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
component name="uninstall" extends="foundry.core" {
	public any function init() {
		return this;
	}
	public any function uninstall(args = [],options = {}) {
		var packages = [];
		var uninstallables = [];
		var emitter = require('emitter');
	    //var async   = require('async');
	    //var nopt    = require('nopt');

	    var save    = require('../util/save');
	    var manager = new fpm.lib.core.manager(args);

	    //if (options.save) save.discard(emitter, manager, names);
 		
	    var resolveLocal = function () {
		  packages = _.flatten(_.values(manager.dependencies));
		  console.log(serialize(manager.dependencies));
		    uninstallables = _.filter(packages,function (pkg) {
		      return _.include(names, pkg.name);
		    });

		    _.forEach(packages, function (pkg, next) {
		      pkg.loadJSON();
		    });
		    
		    showWarnings();
		    uninstall();
		  };


		var showWarnings = function () {
			_.forEach(packages,function (pkg) {
			  if (!isDefined("pkg.json.dependencies")) return;

			  var conflicts = _.intersection(
			    structKeyArray(pkg.json.dependencies),
			    _.pluck(uninstallables, 'name')
			  );

			  _.forEach(conflicts,function (conflictName) {
			  	console.print("@|yellow warning|@ @|cyan #pkg.name#|@ depends on @|white #conflictName#|@");
			  });
			});
		console.log("showWarnings");
		};

		var uninstall = function () {
		console.log("uninstall");
			_.forEach(uninstallables, function (pkg) {

		//console.log("hi");
			  //pkg.on('uninstall', next)
			  pkg.uninstall();
			});
		};

		manager.resolveLocal();
		resolveLocal();

	}
	
	public any function line() {
		
	}
}