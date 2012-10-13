<cfscript>
	public any function print(String action = "",String detail = "") {

		if(action EQ "error") {
			console.print("@|bold,cyan fpm|@ @|bold,red error|@ @|black #detail#|@");
		} else {
			console.print("@|bold,cyan fpm|@ @|bold,white #action#|@ #detail#");
		}
	}
</cfscript>