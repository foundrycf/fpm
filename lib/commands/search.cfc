// ==========================================
// FPM: search API
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
component name="search" extends="foundry.core" {
	public any function init() {
		return this;
	}
	public any function search(name) {
		var source = new fpm.lib.core.source();
		var callback = function (err, results) {
		    //if (err) return emitter.emit('error', err);

		    if (arrayLen(results)) {
		    	for(var i=1; i <= arrayLen(results); i++) {
		    		resultItem = results[i];
		    		print(""," #i#.) #resultItem.name# (#resultItem.url#)");
		    	};
		    } else {
		      print("error","Sorry! No packages found with that query.");
		    }
		  };

		if (len(trim(name))) {
			source.search(name, callback);
		} else {
			source.all(callback);
		}
		
	}
	
	public any function line() {
		
	}
}