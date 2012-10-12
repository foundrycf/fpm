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

	public any function help(name = "") {
		var config    = require('./core/config');
		var console    = require('console');
		var fs    = require('fs');
		var context      = {};
		//var commands     = new fpm.lib.commands.index();
		var templateName = len(trim(arguments.name)) GT 0 ? 'help-' & name : 'help';
		// writeOutput("in");
		//if (!structKeyExists(arguments,'name')) context = { commands: arrayToList(structKeyArray(commands),', ') };
		//_.extend(context, config);

		var tmpl = fileRead(file=expandPath("/fpm/templates/" & templateName & ".txt"),charsetOrBufferSize="UTF-8");
		
		// if(len(trim(arguments.name))) {
		// 	//console.print("#name#");	
		// }
		
		console.print(tmpl);
	}

	line = function (argv) {
	  var options  = nopt(optionTypes, shorthand, argv);
	  var paths    = options.argv.remain.slice(1);

	  if (options.help) return help('install');
	  return [paths, options];
	}
}