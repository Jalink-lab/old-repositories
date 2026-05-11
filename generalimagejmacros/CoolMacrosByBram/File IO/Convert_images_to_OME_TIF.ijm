#@ File (label = "Input directory", style = "directory") inputFolder
#@ String (label = "file extension", value = ".ims") fileExtension
#@ File (label = "Output directory", style = "directory") outputFolder
#@ Integer (label = "Which Pyramid level (1 is highest resolution)?", value=true, min=0) whichPyramid

// Macro to convert .ims files (or other Bioformats-readable) files into image sequences (because Huygens cannot read them)
// Bram van den Broek, b.vd.broek@nki.nl

run("Bio-Formats Macro Extensions");
pyramid_string = "PyramidLayersCount";
print("\\Clear");
if(!File.exists(outputFolder)) File.makeDirectory(outputFolder);

setBatchMode(true);

list = getFileList(inputFolder);
Array.sort(list);

startTime = getTime();

for (i = 0; i < list.length; i++) {
	if(endsWith(list[i], fileExtension)) {
		print("------------------------");
		process_image(list[i]);
	}
}
endTime = getTime();

print("\nFinished in "+d2s((endTime-startTime)/60000,1) + " minutes.");

function process_image(file) {
	path = inputFolder + File.separator + file;
	//Open only the metadata
/*
	run("Bio-Formats Importer", "open=[" + path + "] autoscale color_mode=Default display_metadata rois_import=[ROI manager] view=[Metadata only] stack_order=Default");
	//put metadata into arrays
	metadataTable = getInfo("window.title");
	keys = Table.getColumn("Key",metadataTable);
	values = Table.getColumn("Value");
	run("Close");
print(getInfo("window.type"));
print(keys[0]);
*/
	//Note: BioFormats messes up the numbers. Series in the metadata start with 'series 0', but not in the series_to_open_string, so everything is shifted!
	//Therefore: the arrays have to be sorted correctly, because the series names are not padded with zeros and are sorted incorrectly by BioFormats. Could cause sequence problems.

	/* The following works only for Zeiss .czi
	//Create an (empty) string to feed into Bioformats with the series to open
	series_to_open_string = "";
	count=0;
	for(i=0;i<values.length;i++) {
		if(matches(keys[i], ".*"+pyramid_string+".*")) {	//Also the number of series in the file. 
			//print(i+": "+keys[i]+" = "+values[i]);
			pyramidLevels=values[i];
			//print(pyramidLevels);
			if(whichPyramid > pyramidLevels) {
				print("Too high pyramid requested. Going for pyramid "+pyramidLevels+".");
				series_to_open_string += "series_"+parseInt(pyramidLevels) + count + 1 + " ";	//Use maximum pyramid level for this series
			}
			else series_to_open_string += "series_"+whichPyramid + count + 1 + " ";
			count = count + pyramidLevels + 1;
		}
	}
	*/

	print("Opening " + file + ", resolution "+whichPyramid+"...");
//	startTime = getTime();
	run("Bio-Formats Importer", "open=[" + path + "] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"+whichPyramid);
//	endTime = getTime();
//	print( d2s((endTime-startTime)/60000,1) + " minutes");

	print("Saving image sequence...");
//	File.makeDirectory(outputFolder + File.separator + File.nameWithoutExtension)
//	run("Image Sequence... ", "format=TIFF name=" + File.nameWithoutExtension + " save=" + outputFolder + File.separator + File.nameWithoutExtension + File.separator);
	run("Bio-Formats Exporter", "save="+outputFolder+File.separator+File.nameWithoutExtension+".ome.tif compression=Uncompressed");

	close();
}
