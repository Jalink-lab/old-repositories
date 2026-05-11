#@ File (label = "Input folder", style = "directory") input
#@ File (label = "Output folder", style = "directory") output

#@ Integer (label = "Intensity channel", value=1, style="spinner", min=1, max=3) chIntensity
#@ Integer (label = "Nuclei channel", value=2, style="spinner", min=1, max=3) chNuclei
#@ Integer (label = "Lifetime channel", value=3, style="spinner", min=1, max=3) chLifetime
#@ Boolean (label = "Remove last frame?", value=false) removeLastFrame

#@ String(label = "Handle time series in segmentation", value="average frames", choices={"average frames", "use first frame"}, style="listbox") method
#@ Integer (label = "Median filter radius before nuclei segmentation", value=1, style="spinner", min=0, max=10) filter_radius
#@ String(label = "Local threshold method", value="Niblack", choices={"Bernsen", "Contrast", "Mean", "Median", "MidGrey", "Niblack", "Otsu", "Phansalkar", "Sauvola"}, style="listbox") thresholdMethod
#@ Integer (label = "Local threshold radius", value=50, style="spinner", min=0) ALT_radius
#@ Float (label = "Parameter 1 value", style = "spinner", value=0, min=-10000, max=10000) par1
#@ Float (label = "Parameter 2 value", style = "spinner", value=-8, min=-10000, max=10000) par2
#@ Integer (label = "Lower nucleus diameter limit (um)", style = "spinner", min=0, max=1000, value=4) lower_diameter_limit
#@ Integer (label = "Upper nucleus diameter limit (um)", style = "spinner", min=0, max=1000, value=40) upper_diameter_limit
#@ Float (label = "Minimum circularity", style = "spinner", min=0, max=1, value=0.33) min_circularity


#@ Boolean (label = "Delete rois with low intensity/small cells?", value=true) delete_bad_rois
#@ Float (label = "Minimum cell intensity (gray values)", style = "spinner", min=0, max=1E9, value=5.0) min_cell_intensity
#@ Float (label = "Minimum cell area (um^2)", style = "spinner", min=0, max=1E9, value=100.0) min_cell_area

#@ Boolean (label = "Exclude nuclei on edges", value=true) exclude_edges

#@ Boolean (label = "Refine cell ROIs by thresholding on intensity", value=true) threshold_cells

#@ Boolean (label = "Display intermediate images on screen (debug mode)?", value=false) display_images
#@ Boolean (label = "Pause after each image?", value=false) pause

suffix = ".tif";
//rolling_ball = 50;
lower_size_limit = lower_diameter_limit*lower_diameter_limit/4*PI;
upper_size_limit = upper_diameter_limit*upper_diameter_limit/4*PI;


//Initialize variables
var mean_radius = 1;	//median radius when refining ROIs
var nrOfImages=0;
var current_image_nr=0;
var processtime=0;
output_subfolder = output;	//initialize this variable



saveSettings;

run("Bio-Formats Macro Extensions");
run("Conversions...", "scale");
setBackgroundColor(0, 0, 0);
run("Colors...", "foreground=white background=black selection=#007777");
setOption("BlackBackground", true);	//This is the important one


print("\\Clear");
if(nImages>0) run("Close All");
run("Set Measurements...", "area mean median standard min integrated limit redirect=None decimal=3");
if(display_images==false) setBatchMode(true);

if(!File.exists(output)) {
	create = getBoolean("The specified output folder "+output+" does not exist. Create?");
	if(create==true) File.makeDirectory(output);		//create the output folder if it doesn't exist
	else exit;
}
if(isOpen("Summary")) close("Summary");

scanFolder(input);
processFolder(input);



// function to scan folders/subfolders/files to count files with correct suffix
function scanFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			scanFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			nrOfImages++;
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
			showProgress(current_image_nr/nrOfImages);
			processFile(input, output_subfolder, list[i]);
		}
	}
	print("\\Update1:Finished processing "+nrOfImages+" files.");
	print("\\Update2:Average speed: "+d2s(current_image_nr/processtime,1)+" images per minute.");
	print("\\Update3:Total run time: "+d2s(processtime,1)+" minutes.");

}


function processFile(input, output_subfolder, file) {
	if(nImages>0) run("Close All");

	starttime = getTime();
	print("\\Update1:Processing file "+current_image_nr+"/"+nrOfImages+": " + input + file);
	print("\\Update2:Average speed: "+d2s(current_image_nr/processtime,1)+" images per minute.");
	time_to_run = (nrOfImages-(current_image_nr-1)) * processtime/(current_image_nr-1);
	if(time_to_run<5) print("\\Update3:Projected run time: "+d2s(time_to_run*60,0)+" seconds ("+d2s(time_to_run,1)+" minutes).");
	else if(time_to_run<60) print("\\Update3:Projected run time: "+d2s(time_to_run,1)+" minutes. You'd better get some coffee.");
	else if(time_to_run<480) print("\\Update3:Projected run time: "+d2s(time_to_run,1)+" minutes ("+d2s(time_to_run/60,1)+" hours). You'd better go and do something useful.");
	else if(time_to_run<1440) print("\\Update3:Projected run time: "+d2s(time_to_run,1)+" minutes. ("+d2s(time_to_run/60,1)+" hours). You'd better come back tomorrow.");
	else if(time_to_run>1440) print("\\Update3:Projected run time: "+d2s(time_to_run,1)+" minutes. This is never going to work. Give it up!");
	print("\\Update4:-------------------------------------------------------------------------");

	name = substring(file,0,lastIndexOf(file, "."));	//filename without extension
	name = replace(name,"\\/","-");	//replace slashes by dashes in the name
	name = replace(name," ","_");	//replace slashes by dashes in the name

	//START OF FALCON ANALYSIS-SPECIFIC CODE
	open(input + File.separator + file);
	original=getTitle();
	run("16-bit");

	getDimensions(width, height, channels, slices, frames);
	if(removeLastFrame) {
		Stack.setFrame(frames);
		run("Delete Slice", "delete=frame");
		getDimensions(width, height, channels, slices, frames);
	}
	rename(original);
	frameInterval = Stack.getFrameInterval();

	Stack.setChannel(3);
	setMinAndMax(1500, 4000);
	Stack.setChannel(2);
	run("Enhance Contrast", "saturated=0.35");
	Stack.setChannel(1);
	run("Grays");
	run("Enhance Contrast", "saturated=2");
	run("Duplicate...", "title=Merged duplicate");
	selectWindow(original);
	run("Split Channels");
	selectWindow("C"+chNuclei+"-"+file);
	rename("Nuclei");
	Nuclei = getTitle();
	selectWindow("C"+chIntensity+"-"+file);
	rename("Intensity");
	Intensity = getTitle();
	selectWindow("C"+chLifetime+"-"+file);
	rename("Lifetime");
	Lifetime = getTitle();



	//segment nuclei using Voronoi + refinement
	selectWindow(Nuclei);
	roiManager("reset");
	if(method=="average frames") {
		run("Z Project...", "projection=[Average Intensity]");
		rename(Nuclei+"_filtered");
	}
	else run("Duplicate...", "title=["+Nuclei+"_filtered]");	//Duplicate only the first frame
//	run("Subtract Background...", "rolling="+rolling_ball+" sliding");
	if(filter_radius>0) run("Median...", "radius="+filter_radius);
	//	run("32-bit");
	//	run("ROF Denoise", "theta=10");	//alternative filtering

	resetMinAndMax;
	setMinAndMax(0,255);	//TO DO: Choose one of these

	run("8-bit");
	run("Auto Local Threshold", "method="+thresholdMethod+" radius="+ALT_radius+" parameter_1="+par1+" parameter_2="+par2+" white stack");
	run("Watershed", "stack");
	
	if(exclude_edges) run("Analyze Particles...", "size="+lower_size_limit+"-"+upper_size_limit+" circularity="+min_circularity+"-1.00 show=Masks exclude stack");
	else run("Analyze Particles...", "size="+lower_size_limit+"-"+upper_size_limit+" circularity="+min_circularity+"-1.00 show=Masks stack");
		run("Invert", "stack");
	run("Voronoi", "stack");
	setThreshold(0,0.001);	//threshold on all voronoi distances
	run("Analyze Particles...", "size="+lower_size_limit+"-Infinity show=Nothing clear add stack");

	//Refine cell ROIs based on thresholding on the intensity
	selectWindow(Intensity);
	if(method=="project") {
		run("Z Project...", "projection=[Average Intensity]");
		rename(Intensity+"_filtered");
	}
	else run("Duplicate...", "title=["+Intensity+"_filtered]");	//Duplicate only the first frame

	run("32-bit");
	run("Mean...", "radius="+mean_radius+" stack");
	Intensity_filtered = getTitle();

	if(threshold_cells==true) {
		//create list of ROI coordinates
		var ROI_x = newArray(roiManager("count"));	//containers for selection locations
		var ROI_y = newArray(roiManager("count"));
		for(i=0;i<roiManager("count");i++) {
			roiManager("Select",i);
			Roi.getBounds(x, y, ROI_width, ROI_height);
			//getSelectionBounds(x, y, ROI_width, ROI_height);
			ROI_x[i]=x;
			ROI_y[i]=y;
		}
		roiManager("Show None");
		//run("Clear Results");
		nr_cells = roiManager("count");

	//selectWindow(cells);
	showStatus("Refining "+nr_cells+" ROIs...");
	if(display_images==true) setBatchMode("hide");	//Always do this in Batch Mode
	n=0;
	for(i=0;i<nr_cells;i++) {
		//	if(i%1000==0) {	//becomes messy; better just display every iteration
				showProgress(i/nr_cells);
				showStatus("Refining ROI "+i+" / "+nr_cells+"...");
		//	}
			selectWindow(Intensity_filtered);
			roiManager("Select", i);
			run("Duplicate...", "title=cell_"+i+1);
			//roiManager("Update");

			run("Clear Outside");	//Not necessary because measurements are taken inside the selection (?)
			showStatus("Refining ROI "+i+" / "+nr_cells+"...");
			//setAutoThreshold("MaxEntropy dark");
			setThreshold(maxOf(min_cell_intensity/2,2), 255);	//set the threshold to half the minimum intensity, but at least 2

			List.setMeasurements("limit");
			mean = List.getValue("Mean");
			area = List.getValue("Area");
			if(area > min_cell_area && mean > min_cell_intensity) {
				run("Convert to Mask");
				
				//add one round of particle analyzer to get rid of loose parts in the ROI
				run("Analyze Particles...", "size="+min_cell_area+"-Infinity show=Masks include in_situ");
				run("Invert");
				//run("Fill Holes");	//Not necessary any more
				run("Create Selection");
				getSelectionBounds(x_cell, y_cell, ROI_width_cell, ROI_height_cell);
				close("Mask");

				//re-set ROI locations
				selectWindow(Intensity_filtered);
				run("Restore Selection");
				roiManager("Select", i);
				run("Restore Selection");
				setSelectionLocation(ROI_x[n]+x_cell, ROI_y[n]+y_cell);
				//Roi.move(x_cell, y_cell);
				roiManager("Update");
				roiManager("Rename","cell_"+IJ.pad(i+1,3));
			}
			else {
				//print("ROI "+i+1+" is invalid. Area="+area+", Mean="+mean);
				roiManager("Select", i);
				getSelectionBounds(x_cell, y_cell, ROI_width_cell, ROI_height_cell);
				Roi.setStrokeColor("red");
				setSelectionLocation(ROI_x[n]+x_cell, ROI_y[n]+y_cell);
				roiManager("update");
				roiManager("delete");
				i--;
				nr_cells--;	//remove this cell from the list
			}
			n++;	
			close("cell_"+i+1);
		}
		if(display_images==true) {
			selectWindow(Intensity_filtered);
			setBatchMode("show");
			setBatchMode(false);	//Return from Batch Mode
		}
		print(i+" \/ "+n+" detected cells have area > "+min_cell_area+" and intensity > "+min_cell_intensity);
	}



	selectWindow(Intensity);
	roiManager("Show all without labels");

	showStatus("Measuring cells...");
	nr_cells = roiManager("count");	//Number of valid cells
	mean_lifetime_ = newArray(nr_cells);
	cell_area_ = newArray(nr_cells);
	cell_intensity_ = newArray(nr_cells);

	//Set zeroes to NaN
//	selectWindow(Intensity);
//	run("32-bit");
//	roiManager("show all without labels");
//	for(i=1;i<=frames;i++) {
//		setSlice(i);
//		changeValues(0,0,NaN);	//Set zeroes to NaN, also in intensity stack
//	}
//	selectWindow(Lifetime);
//	run("32-bit");
//	roiManager("show all without labels");
//	for(i=1;i<=frames;i++) {
//		setSlice(i);
//		changeValues(0,0,NaN);	//Set zeroes to NaN, also in intensity stack
//	}
	selectWindow(Lifetime);
	run("Duplicate...", "title=Mask duplicate");
	run("Grays");
	run("Max...", "value=1 stack");	//Replace values larger than 1 to 1, zeros remain zero.
	imageCalculator("Multiply stack", "Mask", Intensity);
	rename(Intensity+"_masked");
	run("Enhance Contrast", "saturated=0.35");
	for(i=1;i<=frames;i++) {
		setSlice(i);
		changeValues(0,0,NaN);	//Set zeroes to NaN, also in intensity stack
	}

	run("Set Measurements...", "area mean redirect=None decimal=3");

	//measure the mean intensity and area of each cell
	selectWindow(Intensity_filtered);
	showStatus("Measuring cell intensity and area...");
	j=0;
	ROIs_to_delete = newArray(nr_cells);
	for(i=0;i<nr_cells;i++) {
		if(i%10==0) showProgress(i/nr_cells);
		roiManager("select",i);
		List.setMeasurements();
		cell_intensity_[i] = List.getValue("Mean");			//intensity in ROI
		cell_area_[i] = List.getValue("Area");				//Area in ROI
/*		//Delete ROIs with dim and/or small cells - NOT NECESSARY ANY MORE (?)
		if(delete_bad_rois==true) {
			if(cell_area_[i] < min_cell_area || cell_intensity_[i] < min_cell_intensity) {	//then delete the ROI
				roiManager("delete");
				i--;
				nr_cells--;	//remove this cell from the list. Next i will overwrite the data. To do: check for the last one
				ROIs_to_delete[j]=i;
				j++;
				deleteFromArray(cell_intensity_, i);
				deleteFromArray(cell_area_, i);
			}
		}
*/
	}
/*
	showStatus("Deleting ROIs...");
	ROIs_to_delete = Array.trim(ROIs_to_delete, j);
	if(ROIs_to_delete.length>0) {
		roiManager("Select",ROIs_to_delete);
		roiManager("Delete");
	}
	nr_cells = roiManager("count");
	print("Deleting "+ROIs_to_delete.length+" cells with intensity < "+min_cell_intensity+" and area > "+min_cell_area+" um^2.\n"+nr_cells+" cells remain.");
*/

	//measure and save intensities
	selectWindow(Intensity+"_masked");
	run("Set Measurements...", "mean redirect=None decimal=2");
	roiManager("deselect");
	showStatus("Measuring...");
	roiManager("Multi Measure");
	selectWindow("Results");
	Table.rename("Results", "Intensity_table");
	renameTableHeaders("Intensity_table");

	
	//multiply lifetime with intensity (for normalization)
	imageCalculator("Multiply create 32-bit stack", Lifetime, Intensity+"_masked");
	rename("Lifetime_times_intensity");

	//measure lifetimes times intensity
	run("Set Measurements...", "mean redirect=None decimal=3");
	roiManager("deselect");
	showStatus("Measuring...");
	roiManager("Multi Measure");
	selectWindow("Results");
	Table.rename("Results", "Lifetime*Intensity_table");
	renameTableHeaders("Lifetime*Intensity_table");

	
	//Normalize lifetime with cell intensity and create tables and plot
	selectWindow("Lifetime*Intensity_table");
	
	headings = Table.headings("Lifetime*Intensity_table");
	headers = split(headings, "\t");
	lifetimeTable = "Lifetime_Data";
	Table.create(lifetimeTable);

	timeArray = Array.getSequence(frames);
	timeArray = MultiplyArraywithScalar(timeArray, frameInterval);
	plotName = substring(file,0,lastIndexOf(file, "."));
	Plot.create(plotName, "time (s)", "Lifetime (ns)");
	Plot.setFrameSize(1024, 768);
	Plot.setLimits(0,frames*frameInterval,1.5,4);
	
	for(i=0;i<nr_cells;i++) {
		showStatus("Computing lifetime...");
		showProgress(i/nr_cells);

		lifetimeTimesIntensityData = Table.getColumn(headers[i+1], "Lifetime*Intensity_table");	//Get the lifetime data for this cell. +1 because the first headers is "".
		intensityData = Table.getColumn(headers[i+1], "Intensity_table");					//Get the intensity data for this cell. 
		lifetimeData = DivideArrays(lifetimeTimesIntensityData,intensityData);				//divide by intensity at every frame to normalize
		lifetimeData = divideArraybyScalar(lifetimeData, 1000);								//convert from ps to ns.

		Table.setColumn(headers[i+1], lifetimeData, lifetimeTable);

		//Generate line with random color
		color1 = toHex(random*255);
		color2 = toHex(random*255);
		color3 = toHex(random*255);
		Plot.setColor("#"+color1+color2+color3);
		Plot.add("line", timeArray, lifetimeData);

		roiManager("select",i);
		roiManager("Set Color", "#"+color1+color2+color3);
	}

	Table.update;
	Table.save(output + File.separator + name + "_lifetime.tsv");

	selectWindow("Merged");
	roiManager("Show All");
	updateDisplay();
	Plot.show();
	if(pause==true) setBatchMode("show");
	saveAs("Tiff", output + File.separator + name + "_plot");
	
	endtime = getTime();
	processtime = processtime+(endtime-starttime)/60000;

	selectWindow("Merged");
	saveAs("Tiff",output + File.separator + name + "_analyzed");
	if(pause==true) {
		setBatchMode("show");
		roiManager("Show all without labels");
		waitForUser("Done analyzing "+file);
	}

	//Save and close tables
	selectWindow("Lifetime*Intensity_table");
	run("Close");
	selectWindow("Intensity_table");
	saveAs("Results", output + File.separator + name + "_intensity.tsv");
	run("Close");
}


//Rename table headers (remove "Mean([cell_xxx])")
function renameTableHeaders(table) {
	headings = Table.headings(table);
	headers = split(headings, "\t");
	for(i=0;i<nr_cells;i++) {
		newHeader = substring(headers[i+1],5,lengthOf(headers[i+1])-1);
		Table.renameColumn(headers[i+1], newHeader);
	}
	Table.update;
}


//Divides the elements of two arrays and returns the new array
function DivideArrays(array1, array2) {
	divArray=newArray(lengthOf(array1));
	for (a=0; a<lengthOf(array1); a++) {
		divArray[a]=array1[a]/array2[a];
	}
	return divArray;
}


//Multiplies all elements of an array with a scalar
function MultiplyArraywithScalar(array, scalar) {
	multiplied_array=newArray(lengthOf(array));
	for (a=0; a<lengthOf(array); a++) {
		multiplied_array[a]=array[a]*scalar;
	}
	return multiplied_array;
}


//Divides all elements of an array by a scalar
function divideArraybyScalar(array, scalar) {
	divided_array=newArray(lengthOf(array));
	for (a=0; a<lengthOf(array); a++) {
		divided_array[a]=array[a]/scalar;
	}
	return divided_array;
}
