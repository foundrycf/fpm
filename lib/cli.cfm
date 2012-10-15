<cfparam name="url.args" default="" />
<cfsetting enablecfoutputonly=true />
<cfscript>
// jarPaths = [];
// jarPaths.add(expandPath('/fpm/deps/JSAP-2.1.jar'));
// variables.loader = createObject("component","foundry.deps.javaloader.JavaLoader").init(jarPaths);
// jsapConfig = loader.create("com.martiansoftware.jsap.xml.JSAPConfig").init();
// jsapConfig.add
// jsap = loader.create("com.martiansoftware.jsap.JSAP").init();
// writeDump(var=jsap,output="console",abort=true);

_ = new foundry.lib.util();

argv = len(trim(url.args)) GT 0? listToArray(url.args," ") : [];

try {
	cli = new commands.index(url.pwd);
	
	if(arrayLen(argv)) {
		command = argv[1];
		commandOpts = "help,index,info,install,list,lookup,register,search,uninstall,update";

		arrayDeleteAt(argv,1);
	} else {
		cli.help();
		abort;
	}

	if(!listFindNoCase(commandOpts,command)) {
		//invalid command
		cli.help();
		abort;
	} else {
		if(arrayLen(argv) GT 0){
			evaluate("cli.#command#(argv)");
		} else {
			evaluate("cli.#command#()");
		}
		abort;
	}
} catch(any err) {
	// writeOutput("fpm error:#chr(10)#" & err.message & chr(10) & left(serialize(err),600));
	// abort;
}
</cfscript>