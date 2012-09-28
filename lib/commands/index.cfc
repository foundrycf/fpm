component name="index" extends="foundry.core" {
	public any function init() {
		var help = require("./commands/help").init();
		var install = require("./commands/install").init();
		var list = require("./commands/list").init();
		var uninstall = require("./commands/uninstall").init();
		var update = require("./commands/update").init();
		var lookup = require("./commands/lookup").init();
		var info = require("./commands/info").init();
		var register = require("./commands/register").init();
		var search = require("./commands/search").init();

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
}