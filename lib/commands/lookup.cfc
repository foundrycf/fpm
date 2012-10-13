// ==========================================
// FPM: lookup API
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
component name="lookup" extends="foundry.core" {
	public any function init() {
		return this;
	}

	public any function lookup(name) {

		var source = new fpm.lib.core.source(outputMode="console");
		source.lookup(name, function (err, theUrl) {
			//print("error",err.message);
			//writeOutput(serialize(err));
		    if (structCount(err) GT 0) {
		      source.search(name, function (err, packages) {
		        if (arrayLen(packages)) {
		        	saveContent variable="suggestions" {
		        	 print("suggestions" & arrayToList(packages,chr(10)));
		        	};

		        	//print("suggestions",suggestions);
		        } else {
		          	print("error","Sorry! No packages found.")
		        }
		      });

		    } else {
		    	
		    }
		});
	}
	
	public any function line() {
		
	}
}