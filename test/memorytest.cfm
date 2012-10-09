<cfapplication name="memorytester" sessionmanagement="true" />

<cfscript>
	oObjectSize = CreateObject("java","nz.co.ventegocreative.coldfusion.memory.CFMemoryCounterAgent");
</cfscript>

<!--- This is our object --->
<cfdump var="#oObjectSize#">

<cfscript>
dataArray = ArrayNew(1);

dataArray[1] = true;
dataArray[2] = 12;
dataArray[3] = "This is a proper string";

dataArray[4] = ArrayNew(1);

dataArray[5] = ArrayNew(1);
dataArray[5][1] = 123232;
dataArray[5][2] = 434354543;

dataArray[6] = ArrayNew(1);

for (i=1; i LTE 12; i=i+1)
{
	dataArray[6][i] = i;
}

dataArray[7] = StructNew();

dataArray[8] = StructNew();
dataArray[8]["firstKey"] = "abc";
dataArray[8]["secondKey"] = "def";
</cfscript>

<cfset myQuery = QueryNew("Name, Time, Advanced", "VarChar, Time, Bit")>
<cfset newRow = QueryAddRow(MyQuery, 2)>
<cfset temp = QuerySetCell(myQuery, "Name", "The Wonderful World of CMFL", 1)>
<cfset temp = QuerySetCell(myQuery, "Time", "9:15 AM", 1)>
<cfset temp = QuerySetCell(myQuery, "Advanced", False, 1)>
<cfset temp = QuerySetCell(myQuery, "Name", "CFCs for Enterprise Applications", 2)>
<cfset temp = QuerySetCell(myQuery, "Time", "12:15 PM", 2)>
<cfset temp = QuerySetCell(myQuery, "Advanced", True, 2)>

<cfset dataArray[9] = myQuery>

<cfsavecontent variable="strVal">
<contentNode contentNodeId="402"><content contentId="209"><P ALIGN="LEFT"><FONT FACE="arial" SIZE="11" COLOR="#000000" LETTERSPACING="0" KERNING="0">dsdsds</FONT></P></content></contentNode>
</cfsavecontent>

<cfset dataArray[10] = XMLParse(strVal)>

<cfset dataArray[11] = session>

<cfset dataArray[12] = application>

<cfset dataArray[13] = oObjectSize>


<table border="1">

<tr>
<td></td>
<td>class</td>
<td>shallow, ignore flyweights</td>
<td>shallow, include flyweights</td>
<td>deep, ignore flyweight</td>
<td>deep, include flyweights</td>
</tr>

<cfloop from="1" to="13" index="j">
<cfoutput>
	<tr>
	<td><cfdump var="#dataArray[j]#"></td>
	<td><cfdump var="#dataArray[j].getClass().getCanonicalName()#"></td>
	<td><cfdump var="#oObjectSize.sizeOf(dataArray[j], true)#"></td>
	<td><cfdump var="#oObjectSize.sizeOf(dataArray[j], false)#"></td>
	<td><cfdump var="#oObjectSize.deepSizeOf(dataArray[j], true)#"></td>
	<td><cfdump var="#oObjectSize.deepSizeOf(dataArray[j], false)#"></td>
	</tr>
</cfoutput>
</cfloop>

</table>
