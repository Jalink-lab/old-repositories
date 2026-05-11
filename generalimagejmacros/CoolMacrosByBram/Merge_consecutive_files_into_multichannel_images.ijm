// Macro to merge individual files into multichannel images.
// If the number of channels is set to 1 it can also be used to copy/rename single-channel files
//
// Author: Bram van den Broek, Netherlands Cancer Institute, April 2020
// email: b.vd.broek@nki.nl

#@ File (label = "Input folder", style = "directory") input
#@ File (label = "Output folder", style = "directory") output
#@ String (label = "File extension", value = ".tif") suffix
#@ String (label = "Output filename base", value = "basename", description="The name that the output file will start with") basename
#@ Integer (label = "Number of channels", value=2, description = "The number of consecutive images that should be merged into a single file") increment
#@ String (label = "Output display mode", choices={"Composite", "Color", "Grayscale"}, style="listBox", description="The display mode of the output file") displayMode

setBatchMode(true);
if(!File.exists(output)) {
	if(getBoolean("Output folder does not exist. Create?")) File.makeDirectory(output);
}

print("-------");
processFolder(input, displayMode);
print("Finished\n");

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input, displaySetting) {
	list = getFileList(input);
	list = Array.sort(list);
	currentImage=0;
	print("Merging " + list.length + " images into " +list.length/increment + " images with " + increment + " channels...");
	if(list.length%increment != 0) showMessage("Warning! The amount of "+suffix+" files ("+list.length+") is not divisible by "+increment+"!\n"+list.length%increment+" image(s) at the end will be skipped, or the macro will crash.");
	for (i = 0; i < list.length-1; i=i+increment) {
		if(endsWith(list[i], suffix)) {
			mergeString = "";
			for(k=0 ; k<increment; k++) {
				open(input + File.separator + list[i+k]);
				mergeString += "c" + k+1 + "=" + list[i+k] + " ";
			}
			run("Merge Channels...", mergeString + "create");
			Stack.setDisplayMode(displayMode);
//			run("Merge Channels...", "c1="+list[i]+" c2="+list[i+1]+" create");
			print(basename + "_" + IJ.pad(currentImage+1,3));
			saveAs("Tiff", output + File.separator + basename + "_" + IJ.pad(currentImage+1,3));
			currentImage++;
			run("Close All");
		}
	}
}
