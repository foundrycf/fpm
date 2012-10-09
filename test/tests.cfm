<cfscript>
src = new lib.core.source();
src.info('systemcommand',function(err,result) {
	//writeDump(var=arguments,abort=true);
});

src.register('fpm-test-module','git://github.com/joshuairl/fpm-test-module.git');
</cfscript>