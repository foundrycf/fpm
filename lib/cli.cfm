<cfparam name="url.args" default="" />
<cfsetting enablecfoutputonly=true />
<cfscript>
argv = len(trim(url.args)) GT 0? listToArray(url.args," ") : [];

try {
	cli = new commands.index();
	
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
		evaluate("cli.#command#('#arrayToList(argv,''',''')#')");
		abort;
	}
} catch(any err) {
	writeOutput("fpm error \n" & serialize(err.additional));
	abort;
}
</cfscript>