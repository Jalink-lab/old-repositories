/* Macro to open certain image series in a file using BioFormats
 * 
 * Bram van den Broek, Netherlands Cancer Institute, 2020
 * b.vd.broek@nki.nl
 *
 */
 
#@ File (label = "Input file", style = "file") inputFile
#@ String (label = "Open image containing name", value = "image") imageString

run("Bio-Formats Macro Extensions");

Ext.setId(inputFile);
Ext.getSeriesCount(seriesCount);

print("\nThe file '"+File.getName(inputFile) + "' has " + seriesCount + " series:");
print("--------------------------------------------------------");
startTime = getTime();
openSeriesString = "";
openSeriesCount = 0;

for (currentSeries = 0; currentSeries < seriesCount; currentSeries++) {	//N.B. The series number starts counting at 0!
	Ext.setSeries(currentSeries);
	Ext.getImageCount(imageCount);
	Ext.getSeriesName(seriesName);
	Ext.getSizeX(sizeX);
	Ext.getSizeY(sizeY);
	Ext.getSizeZ(sizeZ);
	Ext.getSizeC(sizeC);
	Ext.getSizeT(sizeT);
	
	print("Series " + currentSeries+1 + ": "+seriesName+"    ("+sizeX+" x "+sizeY+" x "+sizeZ+", "+sizeC+" channels, "+sizeT+" frames)");
	if(matches(seriesName,".*"+imageString+".*")) {
		openSeriesString += "series_"+currentSeries+1 + " ";
		print("\\Update:Series " + currentSeries+1 + ": "+seriesName+"    ("+sizeX+" x "+sizeY+" x "+sizeZ+", "+sizeC+" channels, "+sizeT+" frames) - will be opened");
		openSeriesCount++;
	}
}
if(openSeriesString!= "") {
	print("Opening "+openSeriesCount+" series...");
	run("Bio-Formats Importer", "open=["+inputFile+"] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT "+openSeriesString);
}
else print("No series found with '"+imageString+"' in the name.");

endTime = getTime();
print("Macro finished in "+d2s((endTime-startTime)/1000,1)+" seconds.");