#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File extension", value = "tif") suffix

#@ Boolean (label = "Crop images?", value=true) cropImages
#@ Integer (label = "Crop x size", style="spinner", min=0, value=1024) crop_x
#@ Integer (label = "Crop y size", style="spinner", min=0, value=1024) crop_y
#@ Integer (label = "Binning (after cropping)", value=1, style="spinner", min=1, value=10) binning


var n=0;
var current_image_nr=0;
var processtime=0;

output_subfolder = output;	//initialize this variable

saveSettings;

run("Conversions...", "scale");
run("Close All");
run("Set Measurements...", "area redirect=None decimal=3");
setBatchMode(true);


if(!File.exists(output)) {
	create = getBoolean("The specified output folder "+output+" does not exist. Create?");
	if(create==true) File.makeDirectory(output);		//create the output folder if it doesn't exist
	else exit;
}

start = getTime();
print("\\Clear");
print("\n");

scanFolder(input);
processFolder(input);

end = getTime();
print("-------------------------------------------------------------------");
print("Finished processing "+n+" images in "+d2s((end-start)/1000,1)+" seconds. ("+d2s((end-start)/1000/n,1)+" seconds per image)");

restoreSettings;





// function to scan folders/subfolders/files to count files with correct suffix
function scanFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			scanFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			n++;
	}
}


// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			output_subfolder = output + File.separator + list[i];	
			if(!File.exists(output_subfolder)) File.makeDirectory(output_subfolder);	//create the output subfolder if it doesn't exist
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix)) {
			current_image_nr++;
			showProgress(current_image_nr/n);
			processFile(input, output_subfolder, list[i]);
		}
	}
}

function processFile(input, output_subfolder, file) {
	starttime = getTime();
	print("\\Update1:Processing image "+current_image_nr+"/"+n+": " + input + file);
	print("\\Update2:Average speed: "+d2s(current_image_nr/processtime,1)+" images per minute.");
	time_to_run = (n/(current_image_nr/processtime)-processtime);
	if(time_to_run<5) print("\\Update3:Projected run time: "+d2s(time_to_run,1)+" minutes.");
	else if(time_to_run<60) print("\\Update3:Projected run time: "+d2s(time_to_run,1)+" minutes. You'd better get some coffee.");
	else if(time_to_run<480) print("\\Update3:Projected run time: "+d2s(time_to_run,1)+" minutes ("+d2s(time_to_run/60,1)+" hours). You'd better go and do something useful.");
	else if(time_to_run<1440) print("\\Update3:Projected run time: "+d2s(time_to_run,1)+" minutes. ("+d2s(time_to_run/60,1)+" hours). You'd better come back tomorrow.");
	else if(time_to_run>1440) print("\\Update3:Projected run time: "+d2s(time_to_run,1)+" minutes. This is never going to work. Give it up!");

	roiManager("reset");
	open(input + File.separator + file);
	//run("Bio-Formats Importer", "open=["+input + File.separator + file+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	name=getTitle;

	//Stack.setDisplayMode("composite");
	//Stack.setChannel(2);
	//run("Green");
	//setMinAndMax(0,10000);
	//Stack.setChannel(1);
	//run("Blue improved");
	//run("Enhance Contrast", "saturated=0.1");

	//*********************
	//THE ACTUAL PROCESSING
	//*********************
	//run("Properties...", "unit=micron pixel_width=0.4920635 pixel_height=0.4920635 voxel_depth=1.0000000");
	if(cropImages == true) run("Canvas Size...", "width="+crop_x+" height="+crop_y+" position=Center zero");
	if(binning!=1) run("Bin...", "x="+binning+" y="+binning+" bin=Average");
	//*********************

	//change filename
	name = file;
	name_new = replace(name, "-Scene-[0-9][0-9][0-9]-\\w\\d*-", " ");
	name_new = substring(name_new, 0, lengthOf(name_new)-4);
	//print(name_new);

	//File.rename(output + File.separator + name, output + File.separator + name_new)
	saveAs("TIF", output_subfolder + File.separator + name_new);
//	print(output_subfolder + name_new);
	run("Close All");
	endtime = getTime();
	processtime = processtime+(endtime-starttime)/60000;
}
