#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output

#@ Boolean (label = "Are pooled detectors used?", value=true) pooled_detectors
#@ Integer (label = "First FLIM (intensity) channel", value=1, style="spinner", min=0, max=5) ch_int
#@ Integer (label = "Nuclei channel", value=1, style="spinner", min=0, max=5) ch_nuc
#@ Boolean (label = "Save as separate Intensity and Lifetime files? (if false, images are merged)", value=false) save_separate

var suffix = ".lif";

// This macro assumes that the lifetime data has been saved using the 'Export raw tiff' option in LAS X.
// The filename should be the same as the series name in the .lif file(s) (without .lif).

run("Bio-Formats Macro Extensions");

if(!File.exists(output)) {
	create = getBoolean("The specified output folder "+output+" does not exist. Create?");
	if(create==true) File.makeDirectory(output);		//create the output folder if it doesn't exist
	else exit;
}


start = getTime();
print("\\Clear");
print("\n");

setBatchMode(true);
processFolder(input);
print("Finished processing");
setBatchMode(false);


end = getTime();



// function to process files in subfolders with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], suffix)) processFile(input, output, list[i]);
	}
}


function processFile(input, output, file) {
	//Open intensity data from the .lif file (containing nuclei) - always series 1
	Ext.setId(input + File.separator + file);
	Ext.getSeriesCount(nr_series);
	
	for(s=0;s<nr_series;s=s+12) {	//iterate per 12, open only the first 
		Ext.setSeries(s);
		Ext.getSeriesName(seriesName);
		print("Processing "+file+" - "+seriesName);
		//name = substring(file,0,lastIndexOf(file, "."));	//filename without extension
		run("Bio-Formats Importer", "open=["+input + File.separator +file+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+s+1);
		intensityImage = getTitle();
		intensityImage=replace(intensityImage,".lif","");	//removes '.lif' in the name
		rename(intensityImage);
		name = intensityImage;

		run("16-bit");
		run("Split Channels");

		if(pooled_detectors==true) {
			imageCalculator("Add stack", "C"+ch_int+"-"+intensityImage, "C"+ch_int+1+"-"+intensityImage);
			rename("Intensity");
			close("C"+ch_int+1+"-"+intensityImage);
		}
		else {
			selectWindow("C"+ch_int+"-"+intensityImage);
			rename("Intensity");
		}
	
		selectWindow("C"+ch_nuc+"-"+intensityImage);
		rename("Nuclei");
//		close("C"+ch_int+"-"+intensityImage);
//		close("C"+ch_int+1+"-"+intensityImage);

		if(save_separate==true) {
			run("Merge Channels...", "c1=Intensity c2=Nuclei create");
			Stack.setChannel(2);
			run("Red");
			Stack.setChannel(1);
			run("Cyan Hot");
			saveAs("Tiff", output + File.separator + name+"_Intensity");
			close();
		}
		
		//Open lifetime data from the .tif file - channel 2
		open(input + File.separator + name+".tif");

		//REMOVE THIS STATEMENT LATER
		run("Duplicate...", "duplicate");
	//
		run("Delete Slice", "delete=channel");	//Delete intensity channel. Doesn't work on stupid automatic virtual stack opener (Bram).
		setMinAndMax(1000, 4000);
		rename("Lifetime");
		run("Physics Black");
		if(save_separate==true) {
			saveAs("Tiff", output + File.separator + name+"_Lifetime");
			close();
		}

		if(save_separate==false) {
			run("Merge Channels...", "c1=Intensity c2=Nuclei c3=Lifetime create");
			Stack.setDisplayMode("color");
			Stack.setChannel(3);
			run("Physics Black");
			setMinAndMax(1000, 4000);
			Stack.setChannel(2);
			run("Red");
			resetMinAndMax();
			Stack.setChannel(1);
			run("Cyan Hot");
			updateDisplay();
			saveAs("Tiff", output + File.separator + name);
			run("Close All");
		}
	}
}
