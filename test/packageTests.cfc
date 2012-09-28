component name="testPackage" extends="mxunit.framework.testcase" {
	public void function Should_resolve_git_URLs_properly() {
		var pkg = new lib.core.package('jquery', 'git://github.com/jquery/jquery.git');
		assert.equal(pkg.gitUrl, 'git://github.com/jquery/jquery.git');
	}

	public void function Should_resolve_git_HTTP_URLs_properly() {
		var pkg = new lib.core.package('jquery', 'git+http://example.com/project.git');
		assert.equal(pkg.gitUrl, 'http://example.com/project.git');
	}

	public void function Should_resolve_git_HTTPS_URLs_properly() {
		var pkg = new lib.core.package('jquery', 'git+https://example.com/project.git');
		assert.equal(pkg.gitUrl, 'https://example.com/project.git');
	}

	public void function Should_resolve_git_URL_tags() {
		var pkg = new lib.core.package('jquery', 'git://github.com/jquery/jquery.git##v1.0.1');
		assert.equal(pkg.tag, 'v1.0.1');
	}

	public void function Should_resolve_github_urls() {
		var pkg = new lib.core.package('jquery', 'git@github.com:twitter/flight.git##v1.0.1');
		assert.equal(pkg.tag, 'v1.0.1');
		assert.equal(pkg.gitUrl, 'git@github.com:twitter/flight.git');
	}

	public void function Should_resolve_url_when_we_got_redirected() {
		var redirecting_url    = 'http://redirecting-url.com';
		var redirecting_to_url = 'http://redirected-to-url.com';

		var redirect_scope = nock(redirecting_url)
		  .defaultReplyHeaders({'location': redirecting_to_url + '/jquery.zip'})
		  .get('/jquery.zip')
		  .reply(302);

		var redirect_to_scope = nock(redirecting_to_url)
		  .get('/jquery.zip')
		  .reply(200, "jquery content");

		var pkg = new lib.core.package('jquery', redirecting_url + '/jquery.zip');

		pkg.on('resolve', function() {
		  assert(pkg.assetUrl);
		  assert.equal(pkg.assetUrl, redirecting_to_url + '/jquery.zip');
		});

		pkg.download();
	};

	public void function Should_clone_git_packages() {
		var pkg = new lib.core.package('jquery', 'git://github.com/maccman/package-jquery.git');

		pkg.on('resolve', function() {
		  assert(pkg.path);
		  assert(fs.existsSync(pkg.path));
		  next();
		});

		pkg.on('error', function (err) {
		  throw new Error(err);
		});

		pkg.clone();
	};

	public void function Should_copy_path_packages() {
		var pkg = new lib.core.package('jquery', __dirname + '/assets/package-jquery');

		pkg.on('resolve', function() {
		  assert(pkg.path);
		  assert(fs.existsSync(pkg.path));
		  next();
		});

		pkg.on('error', function (err) {
		  throw new Error(err);
		});

		pkg.copy();
	};

	public void function Should_error_on_clone_fail() {
		var pkg = new lib.core.package('random', 'git://example.com');

		pkg.on('error', function (err) {
		  assert(err);
		  next();
		});

		pkg.clone();
	};

	public void function Should_load_correct_json() {
		var pkg = new lib.core.package('jquery', __dirname + '/assets/package-jquery');

		pkg.on('loadJSON', function() {
		  assert(pkg.json);
		  assert.equal(pkg.json.name, 'jquery');
		  next();
		});

		pkg.loadJSON();
	};

	public void function Should_resolve_JSON_dependencies() {
		var pkg = new lib.core.package('project', __dirname + '/assets/project');

		pkg.on('resolve', function() {
		  var deps = _.pluck(pkg.getDeepDependencies(), 'name');
		  assert.deepEqual(_.uniq(deps), ["package-bootstrap", "jquery-ui", "jquery"]);
		  next();
		});

		pkg.resolve();
	};

	public void function Should_error_when_copying_fails_from_non_existing_path() {
		var pkg = new lib.core.package('project', __dirname + '/assets/project-non-existent');

		pkg.on('error', function (err) {
		  assert(err);
		  next();
		});

		pkg.resolve();
	};

	public void function Should_copy_files_from_temp_folder_to_local_path() {
		var pkg = new lib.core.package('jquery', 'git://github.com/maccman/package-jquery.git');

		pkg.on('resolve', function() {
		  pkg.install();
		});
		pkg.on('install',function() {
		  assert(fs.existsSync(pkg.localPath));
		  rimraf(config.directory, function(err){
		    next();
		  });
		});
		pkg.clone();
	};
}