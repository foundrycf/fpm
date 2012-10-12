<cfscript>
	public any function print(String action = "",String detail = "") {
		switch (outputMode) {
			case "html":
				if(action EQ "error") {
					writeOutput('<div class="fpm-output-line"><strong>fpm</strong> <span style="color:red;">#action#</span> #detail#</div>');
				} else {
					writeOutput('<div class="fpm-output-line"><strong>fpm</strong> <span style="color:navy;">#action#</span> #detail#</div>');
				}
				//flush.flush();
				break;
			case "console":
				if(action EQ "error") {
					console.print("@|bold,cyan fpm|@ @|bold,red error|@ @|black #detail#|@");
				} else {
					console.print("@|bold,cyan fpm|@ @|bold,white #action#|@ #detail#");
				}
				break;

			default:
				writeOutput("fpm #action# #detail#");
		}
	}
</cfscript>