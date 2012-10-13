/**
* @hint "I should only "
* 
* 
**/
component name="index" extends="foundry.core" {
	public any function init() {
		variables.console = require("console");
		var help = new help();
		var install = new install();
		var list = new list();
		var uninstall = new uninstall();
		var update = new update();
		var lookup = new lookup();
		var info = new info();
		var register = new register();
		var search = new search();
		this['help'] = help.help;
		this['install'] = install.install;
		this['list'] = list.list;
		this['ls'] = list.list;
		this['uninstall'] = uninstall.uninstall;
		this['update'] = update.update;
		this['lookup'] = lookup.lookup;
		this['info'] = info.info;
		this['register'] = register.register;
		this['search'] = search.search;

		this['line'] = {
			'help': help.line,
			'install': install.line,
			'list': list.line,
			'ls': list.line,
			'uninstall': uninstall.line,
			'update': update.line,
			'lookup': lookup.line,
			'info': info.line,
			'register': register.line,
			'search': search.line
		}
	}

	include "../util/print_func.cfm";
}