// ==========================================
// FPM: register API
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
component name="register" extends="foundry.core" {
	public any function init() {
		return this;
	}

	public any function register(name,theUrl) {
		var source = new fpm.lib.core.source(outputMode="console");
		source.register(name,theUrl,function (err) {
			if (structKeyExists(arguments,err)) abort;

			abort;
			//template('register', {name: name, theUrl: theUrl})
		});
	}
	
	public any function line() {
		
	}
}