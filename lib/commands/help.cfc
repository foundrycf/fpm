// ==========================================
// FPM: Help API
// ==========================================
// Copyright 2012 FoundryCF
// Licensed under The MIT License
// http://opensource.org/licenses/MIT
// ==========================================

component name="help" extends="foundry.core" {

	public any function init() {
		return this;
	}

	public any function help(name) {
		var config    = require('./core/config');
		var console    = require('console').init();
		var fs    = require('fs');
		var context      = {};
		var emitter      = new foundry.core.emitter();
		var commands     = new lib.index();
		var templateName = structKeyExists(arguments,'name') ? 'help-' & name : 'help';

		if (!structKeyExists(arguments,'name')) context = { commands: arrayToList(structKeyArray(commands),', ') };
		_.extend(context, config);

		fs.readFile(expandPath('/templates/' & templateName & ".txt"),'utf8',function(err,content) {
			console.print("fpm #name#");
			console.print(content);
		});
		emitter.emit('end',content);
		return emitter;
	}

	line = function (argv) {
	  var options  = nopt(optionTypes, shorthand, argv);
	  var paths    = options.argv.remain.slice(1);

	  if (options.help) return help('install');
	  return module.exports(paths, options);
	}
}