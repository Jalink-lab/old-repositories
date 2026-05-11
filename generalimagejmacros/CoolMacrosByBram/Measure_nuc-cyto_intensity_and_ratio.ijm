/*
 * Macro to intensity in one channel taking nucleus information from a second channel.
 * Required input: an image (stack) with at least these two channels.
 * 
 * Adapted from the foci detection macro. The code still contains a lot of unnecessary stuff.
 * 
 * Multi-file support: the user should first select a file in the to-be-analyzed directory.
 * and set the correct settings in a dialog. Then the user is asked whether to analyze all the
 * files (with the same extension) in the directory and whether the macro should pause after each image.
 * 
 *  
 * Bram van den Broek, Netherlands Cancer Institute, 2014-2019
 * b.vd.broek@nki.nl
 * 
 * 
 */

setOption("BlackBackground", true);
run("Conversions...", " ");
roiManager("reset");
roiManager("Show None");

var pause=false;
var clean=true;
var large_dots=true;
var current_slice = 1;
var median_radius_nuclei = 2;
var lower_limit = 0;
var analyze_all = false;
var pause_after_file = false;
var auto_threshold_nuclei = true;
var watershed = true;
var speed_mode = true;
var remove_pixel_calibration = false;
var logarithm = false;		//this may help if the nuclei signal is very rough
var polynomial_order = 4;	//for shading correction, range 1-10
var camera_offset = 0;		//for shading correction

var nuclei_found = true;
var current_image_nr = 0;
var start_time = 0;
var run_time = 0;
var th_nuc_min = 0;
var th_nuc_max = 255;
var threshold_nuc_bias = 0;		//manual absolute bias of the autothreshold method
var outliers_radius = 5.0;
var outliers_threshold = 50;	//threshold for YAP outlier removal before retreiving median and stddev of nucleus
var avg_median;				//average of outlier-removed median of all nuclei (ok, a bit dubble but you can never be too sure) 
var avg_stddev;				//average of outlier-removed stddev of all nuclei
var background;				//background value (everything but nuclei)
var threshold;
var merged_image;

//settings from dialog
var ch_nuclei = 1;
var ch_YAP = 3;
var nuclei_method_array = newArray("automatically select slice with sharpest nuclei", "maximum intensity projection", "sum slices", "manually select slice");
var nuclei_method = "automatically select slice with sharpest nuclei";	//default method
var Min_Nucleus_Size = 4;	//apparently this is always in pixels - check it!
var Max_Nucleus_Size = 40;
var exclude_edges = false;
var makeBand = true;
var bandSize = 2;
var signalName = "YAP";
var percentile = 0.2 //Intensity percentile that is counted as background 
var shading_correction=false;

YAP_projection_method_array = newArray("maximum intensity projection", "sum slices", "smart z-stack projection (recommended for widefield)", "best slice for every nucleus");
var YAP_projection_method = "maximum intensity projection";	//default
var YAP_diameter = 3.0;	//estimated size of YAP (used in outlier removal and background subtraction)
var min_YAP_size = 0.0;	//minimum YAP size in pixels
var focus_nuclei = false;	//select slices of the nucleus signal with slice numbers found in the YAP channel
var background_correct = true;
var exclude_threshold = 0;
var verbose = false;
var slices;
var editNuclei = true;

var sigma_large = 2*YAP_diameter;	//size of Gaussian blur filter (large) for YAP background subtraction
var sigma_small = 0.5;			//size of Gaussian blur filter (small) for YAP background subtraction



if(nImages>0) run("Close All");
path = File.openDialog("Select a File");
run("Bio-Formats Macro Extensions");

Ext.setId(path);
Ext.getFormat(path, format);
//print(format);

file_name = File.getName(path);
dir = File.getParent(path)+File.separator;

extension = substring(file_name, lastIndexOf(file_name,".")+1);
if (!File.exists(dir+"analyzed")) File.makeDirectory(dir+"analyzed");

savedir = dir+"analyzed";
results_file = savedir+File.separator+File.nameWithoutExtension+"_results.tsv";
ROIs_file = savedir+File.separator+File.nameWithoutExtension+"_ROIs.zip";
log_file = savedir+File.separator+"log.txt";

//Open Metadata only to retreive nr. of channels
run("Bio-Formats Importer", "open=["+path+"] autoscale color_mode=Default display_metadata rois_import=[ROI manager] view=[Metadata only] stack_order=Default");
selectWindow("Original Metadata - "+file_name);
run("Close");
Ext.getSizeC(channels);
Ext.getSizeZ(slices);
Ext.getMetadataValue("Unit", unit);
unit = toString(unit);
print(unit);
if(unit == "\\u00B5m") unit = "um";
Ext.getMetadataValue("BitsperPixel", bits);


file_list = getFileList(dir); //get filenames of directory

//make a list of images with 'extension' as extension.
j=0;
image_list=newArray(file_list.length);	//Dynamic array size doesn't work on Femke's Mac, so first make image_list the maximal size and then trim.
for(i=0; i<file_list.length; i++){
	if (endsWith(file_list[i],extension)) {
		image_list[j] = file_list[i];
		j++;
	}
}
image_list = Array.trim(image_list, j);	//Trimming the array of images

print("\\Clear");
print("Directory contains "+file_list.length+" files, of which "+image_list.length+" "+extension+" files.");
print("\n");

//---------CONFIG FILE INITIATIONS
tempdir = getDirectory("temp");
config_file = tempdir+File.separator+"nuc_cyto_macro_config.txt";
if (File.exists(config_file)) {
	config_string = File.openAsString(config_file);
	config_array = split(config_string,"\n");
	if (config_array.length==15|| config_array.length==13) {
		ch_nuclei = parseInt(config_array[0]);
		ch_YAP = parseInt(config_array[1]);

		Min_Nucleus_Size = parseInt(config_array[2]);
		Max_Nucleus_Size = parseInt(config_array[3]);
		auto_threshold_nuclei = parseInt(config_array[4]);
		threshold_nuc_bias = parseFloat(config_array[5]);
		exclude_edges = parseInt(config_array[6]);

		editNuclei = parseFloat(config_array[7]);
		makeBand = parseInt(config_array[8]);
		bandSize = parseInt(config_array[9]);
		signalName = config_array[10];
		background_correct=parseInt(config_array[11]);
		verbose = parseInt(config_array[12]);

		if(config_array.length==15) nuclei_method = config_array[13];
		if(config_array.length==15) YAP_projection_method = config_array[14];
	}
}


setLocation(0, 0);


//---------OPEN DIALOG
Dialog.createNonBlocking("Options");
	Dialog.addSlider("nuclei channel nr", 1, channels, ch_nuclei);
	Dialog.addSlider("YAP channel nr", 1, channels, ch_YAP);
	//Dialog.setInsets(0, 20, 0);
	if(slices>1) Dialog.addChoice("Select method for nuclei z-projection", nuclei_method_array, nuclei_method);
	/*
	if(unit=="microns") {
		Dialog.addSlider("Mininum nucleus diameter ("+unit+")", 1, 100, Min_Nucleus_Size);
		Dialog.addSlider("Maximum nucleus diameter ("+unit+")", 1, 100, Max_Nucleus_Size);	
	}
	else {
		Dialog.addSlider("Mininum nucleus diameter ("+unit+")", 1, 1000, Min_Nucleus_Size);
		Dialog.addSlider("Maximum nucleus diameter ("+unit+")", 1, 1000, Max_Nucleus_Size);	
	}
	*/
	Dialog.addNumber("Nucleus diameter between", Min_Nucleus_Size, 0, 2, "and");
	Dialog.setInsets(-28, 70, 0);
	Dialog.addNumber("", Max_Nucleus_Size, 0, 2, unit);
	Dialog.addCheckbox("Automatic nuclei segmentation, with threshold bias", auto_threshold_nuclei);
	Dialog.setInsets(-22, 155, 0);
	Dialog.addNumber("", threshold_nuc_bias, 1, 5, "(-"+pow(2,bits)-1+" to "+pow(2,bits)-1+")");
	Dialog.addCheckbox("Exclude nuclei on edge of image", exclude_edges);
	if(slices>1) Dialog.addChoice("Projection method for YAP z-stack", YAP_projection_method_array, YAP_projection_method);
	Dialog.addCheckbox("Manually edit nuclei?", editNuclei);
	Dialog.addCheckbox("Also measure signal in a band around the nucleus?", makeBand);
	if(unit!="pixel" || unit!="pixels" || unit!="") Dialog.addNumber("with thickness", bandSize, 0, 2, unit);
	else  Dialog.addNumber("with thickness", bandSize, 0, 2, "pixels");
	Dialog.addString("signal of interest name", signalName);
	Dialog.addCheckbox("Estimate and subtract background?", background_correct);
	Dialog.addCheckbox("Verbose mode (for debug purposes only)", verbose);
Dialog.show;
	ch_nuclei=Dialog.getNumber();					//0
	ch_YAP=Dialog.getNumber();						//1
	if(slices>1) nuclei_method = Dialog.getChoice();//2	- only when it is a z-stack
	Min_Nucleus_Size = Dialog.getNumber();			//3
	Max_Nucleus_Size = Dialog.getNumber();			//4
	auto_threshold_nuclei = Dialog.getCheckbox();	//5
	threshold_nuc_bias = Dialog.getNumber();		//6
	exclude_edges = Dialog.getCheckbox();			//7
	if(slices>1) YAP_projection_method = Dialog.getChoice();//8	- only when it is a z-stack
	if (slices>1 && YAP_projection_method=="best slice for every nucleus") focus_nuclei=true;
	editNuclei = Dialog.getCheckbox();				//9
	makeBand = Dialog.getCheckbox();				//10
	bandSize = Dialog.getNumber();					//11
	signalName = Dialog.getString();				//12
	background_correct = Dialog.getCheckbox();		//13
	verbose=Dialog.getCheckbox();					//14

//---------SAVE SETTINGS IN CONFIG FILE
save_config_file();

//enquire if all files in the directory should be analyzed if the directory contains more than one files with the same extension.
if(image_list.length>1){
	analyze_all=getBoolean("Analyze all "+image_list.length+" "+extension+" files in this directory with these settings?");
	if(analyze_all==true) pause_after_file=getBoolean("Pause after each file?");
}

start_time=getTime();

//START OF DO...WHILE LOOP FOR ANALYZING ALL IMAGES IN A DIRECTORY
do{

roiManager("reset");
run("Clear Results");

if(analyze_all==true) {
	run("Close All");
	file_name = image_list[current_image_nr];	//retrieve file name from image list
	current_image_nr++;
}
	Ext.openImagePlus(dir+file_name);		//open file using LOCI Bioformats plugin
	if(remove_pixel_calibration==true) run("Properties...", "unit=pixels pixel_width=1 pixel_height=1 voxel_depth=1");
	rename(file_name);
	print("current image: "+file_name);

	Stack.getDimensions(width, height, channels, slices, frames);
	if (bitDepth()!=24 && channels==1) exit("Multi-channel image required.");
	if (bitDepth()==24) run("Make Composite");	//convert RGB images
	if (bitDepth()==16) bits=16;
	else bits=8;
//	run("32-bit");
	Stack.getDimensions(width, height, channels, slices, frames);
	getPixelSize(unit, pw, ph, pd);

extension_index = indexOf(file_name, extension)-1;				//index of file extension
results_file = savedir+File.separator+substring(file_name,0,extension_index)+"_ch"+ch_YAP+"_results.tsv";	//name of results file
merged_image_file = savedir+File.separator+substring(file_name,0,extension_index)+"_ch"+ch_YAP+"_analyzed";//name of analyzed image
ROIs_file = savedir+File.separator+File.nameWithoutExtension+"_ROIs.zip";			//name of file with ROIs
Stack.getDimensions(width, height, channels, slices, frames);


if(verbose==false) setBatchMode(true);

run("Split Channels");
selectWindow("C"+ch_nuclei+"-"+file_name);

//---------METHODS FOR NUCLEI DETECTION
if (slices==1) {};
else if (nuclei_method=="automatically select slice with sharpest nuclei") {
	run("Duplicate...", "title=edges_nuclei duplicate");
	run("Set Measurements...", "area mean standard median stack limit redirect=None decimal=3");
	run("Find Edges", "stack");
	var stdev_array = newArray(slices);
	for(i=0;i<slices;i++) {
		setSlice(i+1);
		run("Measure");
		stdev_array[i] = getResult("StdDev",i);	//measure stddev of edges image; sharpest image has largest stddev.
	}
	Array.getStatistics(stdev_array, min, max);
	index_max = newArray();
	index_max = indexOfArray(stdev_array, max);
	close();
	selectWindow("C"+ch_nuclei+"-"+file_name);
	setSlice(index_max[0]+1);	//select slice with largest standard deviation
	run("Duplicate...", "title=nuclei");
	message("selected slice: "+index_max[0]+1);
}
else if (nuclei_method=="manually select slice") {
	selectWindow("C"+ch_nuclei+"-"+file_name);
	setBatchMode("show");
	waitForUser("Select slice for analysis of nuclei");
	if (verbose==false) setBatchMode("hide");
	current_slice = getSliceNumber();
	setSlice(current_slice);
	run("Duplicate...", "title=nuclei");
}
else if (nuclei_method=="maximum intensity projection") {
	run("Z Project...", "projection=[Max Intensity]");
}
else if (nuclei_method=="sum slices") {
	run("Z Project...", "projection=[Sum Slices]");
}
rename("nuclei");


//---------MAIN PART

segment_nuclei();


//create list of ROI coordinates
var ROI_x = newArray(roiManager("count"));	//containers for selection locations
var ROI_y = newArray(roiManager("count"));
for(i=0;i<roiManager("count");i++) {
	roiManager("Select",i);
	getSelectionBounds(x, y, ROI_width, ROI_height);
	ROI_x[i]=x;
	ROI_y[i]=y;
}

if(nuclei_found==true) {
	selectWindow("C"+ch_YAP+"-"+file_name);
	message("YAP before background subtraction");
	if (slices>1) {
		z_project("C"+ch_YAP+"-"+file_name, YAP_projection_method);
		rename("YAP");
	}
	if (focus_nuclei==true) {	//then also find best slice for the nuclei, but taking the YAP channel as input. It's calculating it again, but is fast ayway.
		z_project("C"+ch_nuclei+"-"+file_name, YAP_projection_method);
		rename("nuclei_slice_corresponding_with_YAP");
	}
	else rename("YAP");

	//data containers
	var nucleus_area = newArray(roiManager("count"));
	var nucleus_mean = newArray(roiManager("count"));
	var nucleus_sum_intden = newArray(roiManager("count"));
	var nucleus_sum_stddev = newArray(roiManager("count"));
	if(focus_nuclei==true) var nucleus_slice_intensity = newArray(roiManager("count"));
	if(focus_nuclei==true) var nucleus_slice_stddev = newArray(roiManager("count"));
	var mean_intensity_YAP_nucleus = newArray(roiManager("count"));
	var total_intensity_YAP_nucleus = newArray(roiManager("count"));
	var stddev_YAP_nucleus = newArray(roiManager("count"));
	var mean_intensity_YAP_cytoplasm = newArray(roiManager("count"));
	var median_intensity_YAP_cytoplasm = newArray(roiManager("count"));
	var total_intensity_YAP_cytoplasm = newArray(roiManager("count"));
	var stddev_YAP_cytoplasm = newArray(roiManager("count"));

	get_nuclei_area_and_intensity();
	YAP_image = analyze_YAP_signal();
//	if(verbose==false) run("Merge Channels...", "c1=background_subtracted c2="+YAP_image+" create");
//	else run("Merge Channels...", "c1=background_subtracted c2="+YAP_image+" create keep");
	if(verbose==false) run("Merge Channels...", "c1=nuclei_shading_corrected c2="+YAP_image+" create");
	else run("Merge Channels...", "c1=nuclei_shading_corrected c2="+YAP_image+" create keep");
	Stack.setChannel(1);
	run("Enhance Contrast", "saturated=0.35");
	Stack.setChannel(2);
	run("Enhance Contrast", "saturated=0.35");
	if(pause_after_file==true && verbose==false) setBatchMode("show");
	else if(analyze_all==false && verbose==false) setBatchMode("show");
	roiManager("Show None");
	roiManager("Show All with labels");
	run("From ROI Manager");	//create overlay with nuclei outlines
	saveAs("Tiff", merged_image_file);
	if(verbose==false) cleanup();
	handle_results();

}
if(analyze_all==true && current_image_nr<image_list.length) {
	if(pause_after_file==true) {
		waitForUser("Inspect results and click OK to continue with the next file");
//		if (verbose==false) setBatchMode(true);
		run("Close All");
	}
	nuclei_found = true; //reset for next loop
}
if(analyze_all==true && current_image_nr==image_list.length) {
	if (verbose==false) setBatchMode("show");
	selectWindow("Log");
	saveAs("text",log_file);
	run_time=round((getTime()-start_time)/1000);
	showMessage("Finished analyzing "+image_list.length+" files in "+run_time+" seconds.");
}
if(analyze_all==true && current_image_nr==image_list.length) {
	run_time=round((getTime()-start_time)/1000);
	print("Finished in "+run_time+" seconds.");
}

//END OF DO...WHILE LOOP
} while(analyze_all==true && current_image_nr<image_list.length);






//---------FUNCTIONS

function segment_nuclei() {
	run("Duplicate...", "title=nuclei_shading_corrected duplicate");
	if(shading_correction==true) run("Fit Polynomial", "x="+polynomial_order+" y="+polynomial_order+" mixed=0");
	//run("Properties...", "channels=[] slices=[] frames=[] unit=pixels pixel_width=1 pixel_height=1 voxel_depth=1.0000000 frame=0 origin=0,0");
	run("Duplicate...", "title=segmented_nuclei duplicate");
	selectWindow("nuclei_shading_corrected");
	run("32-bit");
	selectWindow("segmented_nuclei");
	run("32-bit");
	run("Remove Outliers...", "radius="+YAP_diameter+" threshold="+outliers_threshold+" which=Bright");
	run("Enhance Contrast", "saturated=0.35");
	if(logarithm==true) run("Log", "stack");
	selectWindow("segmented_nuclei");
//waitForUser("before median");
	run("Median...", "radius="+median_radius_nuclei);
//waitForUser("after median");
	run("Duplicate...", "title=nuclei_before_segmentation duplicate");
	resetMinAndMax();
	selectWindow("segmented_nuclei");
	resetMinAndMax();
	if(auto_threshold_nuclei==true)	{
		setAutoThreshold("Li dark");
		getThreshold(min,max);
		resetThreshold();
		setThreshold(min+threshold_nuc_bias,max);
		run("Convert to Mask", "background=Dark black");
	}
	else {
		setAutoThreshold("Li dark");
		getThreshold(min,max);
		resetThreshold();
		setThreshold(min+threshold_nuc_bias,max);
		min_old=min;
		selectWindow("segmented_nuclei");
		setBatchMode("show");
		run("Threshold...");
		selectWindow("Threshold");
		waitForUser("Set threshold for segmentation of nuclei and press OK");
		selectWindow("segmented_nuclei");
		if(verbose==false) setBatchMode("hide");
		getThreshold(min,max);
		threshold_nuc_bias=d2s(min-min_old,1);
		store_bias = getBoolean("Store threshold bias ("+threshold_nuc_bias+") in config file for later use?");
		if (store_bias==true) save_config_file();
		run("Convert to Mask", "  black");
	}
	run("Fill Holes");
	if(watershed==true) run("Watershed");
	setThreshold(127, 255);
	//run("Set Measurements...", "area mean standard centroid stack redirect=None decimal=3");
	if(exclude_edges==true) run("Analyze Particles...", "size="+Min_Nucleus_Size*Min_Nucleus_Size*PI/4+"-"+Max_Nucleus_Size*Max_Nucleus_Size*PI/4+" circularity=0.20-1.00 show=Nothing display exclude add");
	else run("Analyze Particles...", "size="+Min_Nucleus_Size*Min_Nucleus_Size*PI/4+"-"+Max_Nucleus_Size*Max_Nucleus_Size*PI/4+" circularity=0.2-1.00 show=Nothing display add");

	if (editNuclei==true) edit_ROIs("nuclei");
	//Measure nuclei again
	run("Clear Results");
	roiManager("Measure");

	for(j=0;j<roiManager("count");j++) {
		roiManager("select", j);
		roiManager("rename", "nucleus_"+j+1);
	}
	if(roiManager("count")==0) {
		nuclei_found=false;
		print("No nuclei found!");
	}
	else print(roiManager("count")+" nuclei found");
}


function exclude_nuclei() {
	selectWindow("C"+ch_exclude+"-"+file_name);
	if(slices>1) run("Z Project...", " projection=[Max Intensity]");
	rename("exclude_channel");
	run("16-bit");
	run("Set Measurements...", "mean redirect=None decimal=3");
	run("Clear Results");
	ROIs_to_delete = newArray(roiManager("count"));

	j=0;
	for(i=0;i<roiManager("count");i++) {
		roiManager("select",i);
		//List.setMeasurements();
		//mean_intensity_exclude_channel[i] = List.getValue("Mean");
		run("Measure");
		//print("length: "+mean_intensity_exclude_channel.length);
		mean_intensity_exclude_channel[i] = getResult("Mean",i);
		//print("Mean intensity in exclude channel "+ch_exclude+": "+mean_intensity_exclude_channel[i]);
		if(choice_exclude_threshold=="below") {
			if(mean_intensity_exclude_channel[i] < exclude_threshold) {
				ROIs_to_delete[j]=i;
				j++;
			}
		}
		else if(choice_exclude_threshold=="above") {
			if(mean_intensity_exclude_channel[i] > exclude_threshold) {
				ROIs_to_delete[j]=i;
				j++;
			}
		}
	}
	ROIs_to_delete = Array.trim(ROIs_to_delete, j);
	if(ROIs_to_delete.length>0) {
		roiManager("Select",ROIs_to_delete);
		roiManager("Delete");
	}
	print(ROIs_to_delete.length+" nuclei are being excluded. "+roiManager("Count")+" nuclei will be analyzed.");
	if(roiManager("Count")==0) nuclei_found=false;
}


function get_nuclei_area_and_intensity() {
	if(slices>1) selectWindow("C"+ch_nuclei+"-"+file_name);
	else selectWindow("nuclei");
	run("Set Measurements...", "area mean standard integrated redirect=None decimal=3");
	if(slices>1) {
		run("Z Project...", " projection=[Sum Slices]");
		rename("nuclei_summed");
	}
	for(i=0;i<roiManager("count");i++) {
		roiManager("Select", i);
		List.setMeasurements();
		nucleus_area[i] = List.getValue("Area");
		nucleus_mean[i] = List.getValue("Mean");
		nucleus_sum_intden[i]=List.getValue("IntDen")/1000;
		nucleus_sum_stddev[i]=List.getValue("StdDev");
	}
	run("Select None");
	if(focus_nuclei==true) {
		selectWindow("nuclei_slice_corresponding_with_YAP");
		for(i=0;i<roiManager("count");i++) {
			roiManager("Select", i);
			List.setMeasurements();
			nucleus_slice_intensity[i] = List.getValue("Mean");
			nucleus_slice_stddev[i] = List.getValue("StdDev");
		}
	}
	run("Select None");
}


function analyze_YAP_signal() {
	selectWindow("YAP");
	setBatchMode("show");
	Stack.getDimensions(width, height, channels, slices, frames);
	if(slices>1) {
		rename("YAP_stack");
		run("Z Project...", " projection=[Sum Slices]");
		rename("YAP_image_original");
	}
//	run("16-bit");
	rename("YAP_image_original");
	if(shading_correction==true) {
		YAP_image = correct_shading("YAP_image_original", polynomial_order, camera_offset);
	}
	else YAP_image = "YAP_image_original";
	//run("32-bit");
	run("Set Measurements...", "mean median standard integrated redirect=None decimal=3");

	//Estimate YAP background
	if(background_correct==true) {
		getRawStatistics(nPixels, mean, min, max, std, histogram);
		total = 0;
		bin=0;
		while (total < nPixels*percentile) {
			total += histogram[bin];
			bin++;
		} 
		setThreshold(0,bin-1);

		List.setMeasurements("limit");
		//run("Select None");
		resetThreshold();
		YAP_background = List.getValue("Mean");
		print("background in YAP channel: "+YAP_background);
		run("32-bit");
		run("Subtract...", "value="+YAP_background+" slice");
	}
	
	//Measure nuclear YAP intensity
	for(i=0;i<roiManager("count");i++) {
		roiManager("select",i);
		List.setMeasurements();
		mean_intensity_YAP_nucleus[i] = List.getValue("Mean");
		stddev_YAP_nucleus[i] = List.getValue("StdDev");
		total_intensity_YAP_nucleus[i] = List.getValue("IntDen")/1000;
	}
	run("Select None");

	if(makeBand == true) {
		//Create a band around the nucleus
		//if(verbose==true) setBatchMode(true);	//Always do this in batch mode
		setBatchMode("hide");
		for(i=0;i<roiManager("Count");i++) {
			showProgress(i/roiManager("count"));
			roiManager("Select",i);
			run("Make Band...", "band="+bandSize);
			//Roi.getBounds(x, y, width, height);
			//run("Duplicate...", "title=roi_"+i);
			//setBatchMode("show");
			//run("Clear Outside");
			//setAutoThreshold("Li dark");
			//run("Create Selection");
			//resetThreshold();
			//Roi.getBounds(delta_x, delta_y, width, height);
			//close();
			//run("Restore Selection");
			//Roi.move(x+delta_x, y+delta_y);
			roiManager("update");
		}
		//if(verbose==true) setBatchMode(false);

		//Measure cytoplasmic YAP intensity
		for(i=0;i<roiManager("count");i++) {
			roiManager("select",i);
			List.setMeasurements();
			mean_intensity_YAP_cytoplasm[i] = List.getValue("Mean");
			median_intensity_YAP_cytoplasm[i] = List.getValue("Median");
			stddev_YAP_cytoplasm[i] = List.getValue("StdDev");
			total_intensity_YAP_cytoplasm[i] = List.getValue("IntDen")/1000;
		}
	}
	run("Select None");
	return YAP_image;
}


function correct_shading(image, order, offset) {	//requires Fit Polynomial plugin
	selectWindow(image);
	run("Duplicate...", "title=shading");
//	run("Threshold...");
//	setAutoThreshold("Otsu");
//	run("Create Selection");
//	resetThreshold();
	run("Fit Polynomial", "x="+order+" y="+order+" mixed=2 output");
	run("Select None");
	run("32-bit");
	run("Subtract...", "value="+offset);
	getMinAndMax(min,max);
	print(max);
	run("Divide...", "value="+max);
	run("Enhance Contrast", "saturated=0.35");
	imageCalculator("Divide create 32-bit", image,"shading");
	run("Enhance Contrast", "saturated=0.35");
	rename(image+"_shading_corrected");
	shading_corrected_image=getTitle();
	return shading_corrected_image;
}



function background_subtract(image) { //method: Difference of Gaussians (good for small spots)
	showStatus("subtracting background from YAP...");
	selectWindow(image+"_outliers_removed");
	run("Duplicate...", "title="+image+"_large_blur duplicate range=[]");
	run("Gaussian Blur...", "sigma="+sigma_large+" stack");
	selectWindow(image);
	rename(image+"_original");
	run("Duplicate...", "title="+image+"_small_blur duplicate range=[]");
	run("Gaussian Blur...", "sigma="+sigma_small+" stack");
	imageCalculator("Subtract stack", image+"_small_blur",image+"_large_blur");
	selectWindow(image+"_large_blur");
	run("Close");
	selectWindow(image+"_small_blur");
	rename(image);
	run("Enhance Contrast", "saturated=0.1");
	getMinAndMax(min, max);
	setMinAndMax(0, max);
	showStatus("");
	message("background-subtracted image");
}


function z_project(stack, method) {
	selectWindow(stack);
	if (method=="maximum intensity projection") {
		run("Z Project...", " projection=[Max Intensity]");
	}
	else if (method=="sum slices") {
		run("Z Project...", " projection=[Sum Slices]");
	}
	else if (method=="smart z-stack projection (recommended for widefield)") {
		Extended_Depth_of_Field();
		selectWindow("C"+ch_YAP+"-"+file_name+"_focused");
	}
	else if (method=="best slice for every nucleus") {
		run("Duplicate...", "title=best_slices");
		run("Select All");
		setBackgroundColor(0,0,0);
		run("Clear", "slice");	//create black image but retain pixel size, units, bitdepth, etc.
		focus_image = getTitle();
		if (verbose==true) setBatchMode(true); //always use batch mode here
		setBatchMode("show");
		for(i=0;i<roiManager("count");i++) {
			get_best_z_slice(i, "C"+ch_YAP+"-"+file_name, stack, focus_image, "StdDev", 0);	//stack does not need to be twice the same, e.g. "C"+ch_YAP+"-"+file_name
		}
		run("Select None");
		if (verbose==true) setBatchMode(false);
	}
}


function get_best_z_slice(nucleus_nr, image_measure, image_copy_from, image_paste_to, measure_type, start_index) {
	selectWindow(image_measure);
	roiManager("Select", start_index+nucleus_nr);
	var array = newArray(slices);

	//measure mean intensity and standard deviation of every slice and return the largest value
	for(j=0;j<slices;j++) {
		setSlice(j+1);
		List.setMeasurements();
		array[j] = List.getValue(measure_type);	//best slice has largest mean/stdDev/...
	}
	Array.getStatistics(array, min, max);
	index_max = newArray();
	index_max = indexOfArray(array, max);

	//print("cell "+i+": slice "+index_max[0]+1);
	showStatus("cell "+i+": slice "+index_max[0]+1);

	//copy the (whole) nucleus to the new image
	selectWindow(image_copy_from);
	setSlice(index_max[0]+1);		//select correct slice
	resetMinAndMax();
	roiManager("Select", nucleus_nr);
	run("Copy");
	selectWindow(image_paste_to);
	roiManager("Select", nucleus_nr);
	run("Paste");
}


function cleanup() {
	if(clean==true) {
		for(i=1;i<=channels;i++) {
			if(isOpen("C"+i+"-"+file_name)) {
				close("C"+i+"-"+file_name);
			}
		}
		close("nuclei");
		close("YAP");
		close("YAP_original");
	}
}



function handle_results() {
	run("Clear Results");
	run("Input/Output...", "file=.tsv use_file copy_row copy_column save_column");
	for(i=0;i<roiManager("Count");i++) {
		setResult("nucleus_nr", i, i+1);
		setResult("DAPI_area ("+unit+"^2)", i, nucleus_area[i]);
		setResult("DAPI_mean", i, nucleus_mean[i]);
		setResult("DAPI_total (x10^3)", i, nucleus_sum_intden[i]);
		//setResult("nuc_total_stddev", i, nucleus_sum_stddev[i]);
		if(slices>1 && focus_nuclei==true) setResult("DAPI_slice_intensity", i, nucleus_slice_intensity[i]);
		if(slices>1 && focus_nuclei==true) setResult("DAPI_slice_stddev", i, nucleus_slice_stddev[i]);
		setResult(signalName+"_mean_nuc", i, mean_intensity_YAP_nucleus[i]);
		setResult(signalName+"_total_nuc (x10^3)", i, total_intensity_YAP_nucleus[i]);
		if(makeBand == true) setResult(signalName+"_mean_cyto", i, mean_intensity_YAP_cytoplasm[i]);
		if(makeBand == true) setResult(signalName+"_median_cyto", i, median_intensity_YAP_cytoplasm[i]);
		if(makeBand == true) setResult(signalName+"_total_cyto (x10^3)", i, total_intensity_YAP_cytoplasm[i]);
		if(makeBand == true) setResult(signalName+"_nuc_meancyto_ratio", i, mean_intensity_YAP_nucleus[i]/mean_intensity_YAP_cytoplasm[i]);	
		if(makeBand == true) setResult(signalName+"_nuc_mediancyto_ratio", i, mean_intensity_YAP_nucleus[i]/median_intensity_YAP_cytoplasm[i]);	
//		setResult("stddev_"+signalName+"_nucleus", i, stddev_YAP_nucleus[i]);
	}
	updateResults();

	print("\n");
	
	selectWindow("Results");
	saveAs("text", results_file);
	roiManager("Select All");
	roiManager("Save", ROIs_file);
}



function indexOfArray(array, value) {
	count=0;
	for (a=0; a<lengthOf(array); a++) {
		if (d2s(array[a],3)==d2s(value,3)) {
			count++;
		}
	}
	if (count>0) {
		indices=newArray(count);
		count=0;
		for (a=0; a<lengthOf(array); a++) {
			if (array[a]==value) {
				indices[count]=a;
				count++;
			}
		}
		return indices;
	}
}


function message(txt) {
if (pause==true){
	waitForUser(txt);
	}
}


function save_config_file() {
	config_file = File.open(tempdir+File.separator+"nuc_cyto_macro_config.txt");
	print(config_file, ch_nuclei);
	print(config_file, ch_YAP);
	print(config_file, Min_Nucleus_Size);
	print(config_file, Max_Nucleus_Size);
	print(config_file, auto_threshold_nuclei);
	print(config_file, threshold_nuc_bias);
	print(config_file, exclude_edges);
	print(config_file, editNuclei);
	print(config_file, makeBand);
	print(config_file, bandSize);
	print(config_file, signalName);
	print(config_file, background_correct);
	print(config_file, verbose);
	if(slices>1) print(config_file, nuclei_method);
	if(slices>1) print(config_file, YAP_projection_method);
	File.close(config_file);
}

function Extended_Depth_of_Field() {

	radius=3;
	
	//Get start image properties
	w=getWidth();
	h=getHeight();
	d=nSlices();
	source=getImageID();
	origtitle=getTitle();
	rename("tempnameforprocessing");
	sourcetitle=getTitle();

	//Generate edge-detected image for detecting focus
	run("Duplicate...", "title=["+sourcetitle+"_Heightmap] duplicate range=1-"+d);
	heightmap=getImageID();
	heightmaptitle=getTitle();
	run("Find Edges", "stack");
	run("Maximum...", "radius="+radius+" stack");

	//Alter edge detected image to desired structure
	run("32-bit");
	for (x=0; x<w; x++) {
		showStatus("Creating focused image from stack...");
		showProgress(x/w);
		for (y=0; y<h; y++) {
			slice=0;
			max=0;
			for (z=0; z<d; z++) {
				setZCoordinate(z);
				v=getPixel(x,y);
				if (v>=max) {
					max=v;
					slice=z;
				}
			}
			for (z=0; z<d; z++) {
				setZCoordinate(z);
				if (z==slice) {
					setPixel(x,y,1);
				} else {
					setPixel(x,y,0);
				}
			}
		}
	}
	run("Gaussian Blur...", "sigma="+radius+" stack");
	
	//Generation of the final image
	
	//Multiply modified edge detect (the depth map) with the source image
	run("Image Calculator...", "image1="+sourcetitle+" operation=Multiply image2="+heightmaptitle+" create 32-bit stack");multiplication=getImageID();
	//Z project the multiplication result
	run("Z Project...", "start=1 stop="+d+" projection=[Sum Slices]");
	//Some tidying
	rename(origtitle+"_focused");
	selectImage(heightmap);
	close();
	selectImage(multiplication);
	close();
	selectImage(source);
	rename(origtitle);
	
}


function edit_ROIs(image1) {
shift=1;
ctrl=2; 
rightButton=4;
alt=8;
leftButton=16;
insideROI = 32;

flags=-1;
//x2=-1; y2=-1; z2=-1; flags2=-1;

selectWindow(image1);
roiManager("Show All without labels");
setOption("DisablePopupMenu", true);
setBatchMode(true);
resetMinAndMax();
setBatchMode("show");
color_ROIs();
print("\\Clear");
print("Delete, combine and draw new ROIs. \n- Left clicking while holding CTRL deletes a ROI.\n- Select multiple ROIs with shift-left mouse button and right-click to merge them into one ROI. \n- Draw new ROIs using the magic wand or the freehand tool and press 't' to add. \n- Press space bar when finished editing.\n");
showMessage("Delete, combine and draw new ROIs. \n- Left clicking while holding CTRL deletes a ROI.\n- Select multiple ROIs with shift-left mouse button and right-click to merge them into one ROI. \n- Draw new ROIs using the magic wand or the freehand tool and press 't' to add. \n- Press space bar when finished editing.\n\nThis information is also printed in the log window.");
print("\nStarting editing "+roiManager("count")+" ROIs...");


setTool("freehand");
roiManager("Show All without labels");
setOption("DisablePopupMenu", true);

nROIs = roiManager("Count");


while(!isKeyDown("space")) {				//exit by pressing space bar
	getCursorLoc(x, y, z, flags);

/*
	if(flags==16)	{	// (De)select single ROI with left click - works but prevents drawing of new ROIs
		for(i=0;i<roiManager("Count");i++) {
			roiManager("Select",i);
			selected = Roi.getProperty("selected");
			if(selected==true) {						//deselect previously selected ROI
				Roi.setStrokeColor("none");
				Roi.setFillColor("green");
				Roi.setProperty("selected",false);	
			}
			if(Roi.contains(x, y)==true && selected==false) {
			selected = Roi.getProperty("selected");
				//click to select a single ROI
				if(flags==16 && selected==false) {		//select ROI
					//print("selecting ROI "+i);
					Roi.setStrokeColor("red");
					Roi.setFillColor("blue");
					Roi.setProperty("selected",true);
				}
				else if(flags==16 && selected==true) {	//deselect ROI
					//print("deselecting ROI "+i);
					Roi.setStrokeColor("none");
					Roi.setFillColor("green");
					Roi.setProperty("selected",false);
				}
			}
		}
		roiManager("Deselect");
		run("Select None");
		updateDisplay();
	}
*/
	
	if(flags==17 || flags==18)	{	// (De)select multiple ROIs with shift-leftclick; delete ROI with rightclick
		for(i=0;i<roiManager("Count");i++) {
			roiManager("Select",i);
			if(Roi.contains(x, y)==true) {
			selected = Roi.getProperty("selected");
				//click to select a single ROI
				if(flags==17 && selected==false) {		//select ROI
					//print("selecting ROI "+i);
					Roi.setStrokeColor("red");
					Roi.setProperty("selected",true);
				}
				else if(flags==17 && selected==true) {	//deselect ROI
					//print("deselecting ROI "+i);
					Roi.setStrokeColor("cyan");
					//Roi.setFillColor("1900ffff");
					Roi.setProperty("selected",false);
				}
				else if(flags==18) {	//delete ROI
					roiManager("Delete");
					for(j=0;j<roiManager("Count");j++) {	//deselect all ROIs and rename
						roiManager("Select",j);
						roiManager("Rename", "ROI "+j);
					}
				}
			}
		}
		roiManager("Deselect");
		run("Select None");
		updateDisplay();
	}


	if(flags==4) {	//right button: combine selected ROIs
		selected_ROI_array = newArray(roiManager("Count"));	//create array with indices of selected ROIs
		j=0;
		for(i=0;i<roiManager("Count");i++) {
			roiManager("select",i);
			selected = Roi.getProperty("selected");
			if(selected==true) {
				selected_ROI_array[j] = i;
				j++;
				//print(j);
			}
		}
		//check if more than one ROI is selected. If yes, combine the selected ROIs and update the list
		selected_ROI_array = Array.trim(selected_ROI_array,j);
		//print(selected_ROI_array.length + " ROIs selected");
		if(selected_ROI_array.length > 1) {
			//print("combining ROIs:");
			//Array.print(selected_ROI_array);
			roiManager("Select",selected_ROI_array);
			roiManager("Combine");
			roiManager("Update");
//			for(i=1;i<selected_ROI_array.length;i++) {	
			to_delete_array = Array.copy(selected_ROI_array);								//selecting and deleting redundant ROIs
			to_delete_array = Array.slice(selected_ROI_array,1,selected_ROI_array.length);	//create array without the first element
				roiManager("Deselect");
				//print("deleting ROIs:");
				//Array.print(to_delete_array);
				roiManager("select", to_delete_array);
				roiManager("Delete");
			roiManager("Select",selected_ROI_array[0]);
			//print("repairing ROI "+selected_ROI_array[0]);
			run("Enlarge...", "enlarge=1 pixel");			//remove wall between ROIs by enlarging and shrinking with 1 pixel
			run("Enlarge...", "enlarge=-1 pixel");
			roiManager("Update");
			
			setKeyDown("none");
			
			color_ROIs();
		}
	}


	if(nROIs!=roiManager("Count")) {	//change in the number of ROIs 
		run("Select None");
		color_ROIs();
		nROIs = roiManager("Count");
	}

	else wait(50);
}	//end of while loop

//Deselect and rename all ROIs once more
color_ROIs();
//print("Done editing. "+roiManager("count")+" ROIs remain.");
}


function color_ROIs() {
	run("Remove Overlay");

	for(j=0;j<roiManager("Count");j++) {	//fill all ROIs
		roiManager("Select",j);
		roiManager("Rename", "ROI "+j+1);
		Roi.setProperty("selected",false);
		//Roi.setFillColor("1900ffff");	//10% cyan fill
	}
	roiManager("Deselect");
	if(roiManager("count")>0) run("From ROI Manager");	//Add overlay containing the ROI fill
	roiManager("Select All");
//	roiManager("Set Color", "cyan");
	roiManager("Deselect");
	roiManager("Show All without labels");
	updateDisplay();
}
