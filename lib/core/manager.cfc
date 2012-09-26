// ==========================================
// BOWER: Manager Object Definition
// ==========================================
// Copyright 2012 Twitter, Inc
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
component {
	variables.Package = require('./package');
	variables.config = require('./config');
	variables.prune = require('../util/prune');
	variables.events = require('events');
	variables.async = require('async');
	variables.path = require('path');
	variables.glob = require('glob');
	variables.fs = require('fs');
	this.dependencies = {};
	this.cwd = getPageContext();
	this.endpoints = endpoints || [];
}