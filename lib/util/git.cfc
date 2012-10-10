component accessors=true extends="foundry.lib.module" {
	property type="any" name="repository";
	property type="any" name="gitdirectory";

	public any function init() {
    	var path = require("path");
    	var jarpaths = [path.resolve(path.dirname(getCurrentTemplatePath()),'../../deps/org.eclipse.jgit-2.1.0.201209190230-r.jar')];

		variables.java = createObject("component","foundry.deps.javaloader.JavaLoader").init(jarpaths);
   		//var repoFile = createObject("java","java.io.File").init(repository);
   		this.Git = java.create("org.eclipse.jgit.api.Git");

		return this;
	}

	/*
	CLASS FUNCTIONS
	*/
	public any function clone(gituri,localpath) {
		var repositoryBuilder = java.create("org.eclipse.jgit.lib.BaseRepositoryBuilder").init();
		var command = this.Git.cloneRepository();
		var repoDir = createObject("java","java.io.File").init(localpath);

		repositoryBuilder.setWorkTree(repoDir);

		command.setDirectory(repoDir);
		command.setUri(gituri);

		var result = {
			err:{},
			result:""
		}
		try {
			result = {
				err:{},
				result:command.call()
			}

		} catch(any error) {
			result = {
				err:error,
				result:{}
			}

			repositoryBuilder.findGitDir();
			var repository = repositoryBuilder.setup().build();
			this.setRepository(repository);
			this.Git.init(repository);

			return result;
		}

		repositoryBuilder.findGitDir();
		var repository = repositoryBuilder.setup().build();
		this.setRepository(repository);
		this.Git.init(repository);

		return result;
	}

	/*
	INSTANCE FUNCTIONS
	ALL OF THESE REQUIRE A REPO;
	*/
	public any function checkout() {
		var command = this.Git.checkout();
		command.setCreateBranch(true);
		var result = {
			err:{},
			result:""
		}
		try {
			result = {
				err:{},
				result:command.call()
			}
		} catch(any error) {
			result = {
				err:error,
				result:{}
			}

			return result;
		}
		return result;
	}

	public any function fetch() {
		var command = this.Git.fetch();
		var result = {
			err:{},
			result:""
		}
		try {
			result = {
				err:{},
				result:command.call()
			}
		} catch(any error) {
			result = {
				err:error,
				result:{}
			}

			return result;
		}
		return result;
	}

	public any function tagList() {
		var command = this.Git.tagList();
		var tags = [];

		var result = {
			err:{},
			result:""
		}
		try {
			var tagObjs = command.call();

			for(tagObj in tagObjs) {
				tags.add(replace(tagObj.getName(),'refs/tags/',''));
			}

			result = {
				err:{},
				result:tags
			}
		} catch(any error) {
			result = {
				err:error,
				result:{}
			}

			return result;
		}
		return result;
	}
}