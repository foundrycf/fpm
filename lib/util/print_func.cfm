<cfscript>
	public any function print(String action = "",String detail = "") {

		if(action EQ "error") {
			console.print("@|bold,cyan fpm|@ @|bold,red error|@ @|white #detail#|@");
		} else {
			console.print("@|bold,cyan fpm|@ @|bold,white #action#|@ @|white #detail#|@");
		}
	}
</cfscript>