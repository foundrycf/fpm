component name="testPackage" extends="mxunit.framework.testcase" {
	public void function setUp() {
		_ = new foundry.core.util();
		console = new foundry.core.console();
		//fs = new foundry.core.fs();
		console.log("===== start ======");
	}

	public void function tearDown() {
		console.log("====== end =======");
	}

	public void function Should_resolve_git_URLs_properly() {
		var pkg = new lib.core.package('jquery', 'git://github.com/jquery/jquery.git');
		assertEquals( 'git://github.com/jquery/jquery.git',pkg.gitUrl);
	}

	public void function Should_resolve_git_HTTP_URLs_properly() {
		var pkg = new lib.core.package('jquery', 'git+http://example.com/project.git');
		assertEquals( 'http://example.com/project.git',pkg.gitUrl);
	}

	public void function Should_resolve_git_HTTPS_URLs_properly() {
		var pkg = new lib.core.package('jquery', 'git+https://example.com/project.git');
		assertEquals( 'https://example.com/project.git',pkg.gitUrl);
	}

	public void function Should_resolve_git_URL_tags() {
		var pkg = new lib.core.package('jquery', 'git://github.com/jquery/jquery.git##v1.0.1');
		assertEquals( 'v1.0.1',pkg.tag);
	}

	public void function Should_resolve_github_urls() {
		var pkg = new lib.core.package('jquery', 'git@github.com:twitter/flight.git##v1.0.1');
		assertEquals( 'v1.0.1',pkg.tag);
		assertEquals( 'git@github.com:twitter/flight.git',pkg.gitUrl);
	}

	// public void function Should_resolve_url_when_we_got_redirected() {
		
	// 	var pkg = new lib.core.package('jquery', 'https://github.com/joshuairl/semver/zipball/master');

	// 	pkg.on('resolve', function() {
	// 	  assert(!_.isEmpty(pkg.assetUrl));
	// 	  //assertEquals( redirecting_to_url + '/jquery.zip',pkg.assetUrl);
	// 	});

	// 	pkg.download();
	// 	pkg.emit('resolve');
	// };

	public void function Should_clone_git_packages() {
		var pkg = new lib.core.package('mkdirp', 'git@github.com:slamkajs/mkdirp.git');
			
		pkg.clone();

		assert(!_.isEmpty(pkg.path));
		assert(directoryExists(pkg.path));
	};

	public void function Should_copy_path_packages() {
		console.print("Should_copy_path_packages");
		var pkg = new lib.core.package('jquery', expandPath('/test/assets/package-jquery'));

		pkg.copy();
		console.print("pkg.path: " & serialize(pkg.path));
		assert(!_.isEmpty(pkg.path));
		assert(directoryExists(pkg.path));
	};

	public void function Should_error_on_clone_fail() {
		var pkg = new lib.core.package('random', 'git://example.com');

		pkg.on('error', function (err) {
		  assert(structKeyExists(arguments,'err'));
		});

		pkg.clone();
	};

	public void function Should_load_correct_json() {
		var pkg = new lib.core.package('async', expandPath("/test/assets/async"));

		pkg.loadJSON();

		assert(!_.isEmpty(pkg.json));
		assertEquals( 'async',pkg.json.name);
	};

	public void function Should_resolve_JSON_dependencies() {
		var pkg = new lib.core.package('semver', expandPath("/test/assets/semver"));

		pkg.resolve();

		var deps = _.pluck(pkg.getDeepDependencies(), 'name');
		assertEquals(["UnderscoreCF"], _.uniq(deps));
	};

	public void function Should_error_when_copying_fails_from_non_existing_path() {
		var pkg = new lib.core.package('project', expandPath('/test/assets/project-non-existent'));
		try {
			pkg.resolve();
		} catch(any err) {
			assert(isDefined("err"),err.message);	
		}
	};

	public void function Should_copy_files_from_temp_folder_to_local_path() {
		var pkg = new lib.core.package('fpm-test-module', 'git://github.com/joshuairl/fpm-test-module.git');
		//pkg.resolve();

		pkg.clone();

		//pkg.install();

		// assert(directoryExists(pkg.localPath));
	 //      directoryDelete(config.directory);
		//pkg.fetch();
	};
}