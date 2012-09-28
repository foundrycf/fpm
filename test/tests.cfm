<cfscript>
fpm = new lib.index();

writeDump(var=fpm.install('/foundry_modules/'),abort=true);
</cfscript>