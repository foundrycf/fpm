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
		if(arrayLen(argv) GT 0){
			evaluate("cli.#command#('#arrayToList(argv,''',''')#')");
		} else {
			evaluate("cli.#command#()");
		}
		abort;
	}
} catch(any err) {
	writeOutput("fpm error:#chr(10)#" & err.message & chr(10) & serialize(err.additional));
	abort;
}
</cfscript>