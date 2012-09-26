component name="index" extends="foundry.core" {
	this['help'] = require("./help");
	this['install'] = require("./install");
	this['list'] = require("./list");
	this['ls'] = require("./list");
	this['uninstall'] = require("./uninstall");
	this['update'] = require("./update");
	this['lookup'] = require("./lookup");
	this['info'] = require("./info");
	this['register'] = require("./register");
	this['search'] = require("./search");
}