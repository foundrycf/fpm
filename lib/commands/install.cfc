// ==========================================
// FPM: Install API
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
component name="install" extends="foundry.core" {
  public any function init() {
    return this;
  }

  public any function install(paths, options) {
    var emitter = require('emitter');
    var async   = require('async');
    //var nopt    = require('nopt');

    var save    = require('../util/save');
    var list    = require('./list');
    var help    = require('./help');

    var optionTypes = { help: false };
    var shorthand   = { 'h': ['--help'], 'S': ['--save'] };
    var manager = require("./core/manager").init();
    if (structKeyExists(arguments,'options') && structKeyExists(arguments.options,'save')) save(emitter, manager, paths);

    manager.on('data'    , _.bind(emitter.emit,emitter,'data'));
    manager.on('error'   , _.bind(emitter.emit,emitter,'error'));
    manager.on('resolve' , _.bind(emitter.emit,emitter,'end'));
    manager.resolve();

    return emitter;
  };

  public any function line(argv) {
    var options  = nopt(optionTypes, shorthand, argv);
    var paths    = options.argv.remain.slice(1);

    if (options.help) return help('install');
    return module.exports(paths, options);
  };
}
