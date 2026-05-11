#@ File (label = "Output folder", style = "directory") outputFolder
#@ Integer (label = "Intensity cutoff (below is set to zero)", style = "spinner", min=0, max=1000, value=5) intensitycutOff
#@ Float (label = "Median radius for filtering peroxisomes prior to segmentation", style = "spinner", min=0, max=10, value=1.0) medianRadius
#@ Integer (label = "Auto local threshold radius", style = "spinner", min=0, max=1000, value=5) autoThresholdRadius
#@ Integer (label = "Auto local threshold offset (higher = more strict)", style = "spinner", min=0, max=1000, value=10) autoThresholdParameter1
#@ Integer (label = "Minimum peroxisome size (pixels)", style = "spinner", min=0, max=1000, value=5) minPeroxisomeSize
#@ Integer (label = "Auto local threshold radius", style = "spinner", min=0, max=1000, value=5) autoThresholdRadius
#@ Integer (label = "Maximum displayed intensity value in overlay (lower = brighter)", style = "spinner", min=0, max=1000, value=50) maxInt
#@ Float (label = "Minimum displayed lifetime value", style = "spinner", min=0, max=10, value=1.0) minTau
#@ Float (label = "Maximum displayed lifetime value", style = "spinner", min=0, max=100, value=2.2) maxTau

autoThresholdParameter1 = -autoThresholdParameter1;

smoothOverlay = false;	//Mean filter with 1 pixel radius
smoothRadius = 0.5

saveSettings();

if(nImages>0) {}
else {
	path = File.openDialog("Select a file to analyze");
	open(path);
}
originalImage = getTitle();

setBackgroundColor(0, 0, 0);
run("Conversions...", " ");
roiManager("reset");
run("Select None");
run("Set Measurements...", "area mean redirect=None decimal=3");
setTool("freehand");
colors = newArray("blue", "red", "#00a000", "#ffa000", "Magenta");

setBatchMode(true);

getDimensions(width, height, channels, slices, frames);
run("Duplicate...", "title=temp duplicate");
run("32-bit");

selectWindow(originalImage);
Stack.setChannel(2);
setMinAndMax(minTau*1000, maxTau*1000);
run("physics");
Stack.setChannel(1);
run("Grays");
run("Enhance Contrast", "saturated=3");

//Let the user select the cells of interest; color the cells and add as overlay.
waitForUser("Select cells and press 't' to add to the ROI manager. Press OK to continue.");
nrCells = roiManager("count");
for (i=0; i<nrCells; i++) {
	roiManager("select",i);
	roiManager("Rename", "cell_"+i+1);
	roiManager("Set Color", colors[i%colors.length]);
	run("Add Selection...");
}
run("Select None");

//Clear the image outside the cells
selectWindow("temp");
if(nrCells>1) {
	roiManager("select all");
	roiManager("Combine");
}
else roiManager("select", 0);
run("Clear Outside", "stack");
run("Select None");
roiManager("reset");

//Create a mask on intensity, multiply with the original(temp) and set background to NaN
run("Duplicate...", "title=Mask duplicate channels=1");
run("Grays");
changeValues(0,intensitycutOff,0);
changeValues(intensitycutOff,65535,1);
imageCalculator("Multiply stack", "temp", "Mask");
//rename(original+"_masked");
run("Enhance Contrast", "saturated=0.35");
for(f=1 ; f<=frames ; f++) {
	Stack.setFrame(f);
	for(c=1 ; c<=channels ; c++) {
	Stack.setChannel(c);
		changeValues(0,0,NaN);	//Set zero to NaN, also in intensity stack
	}
}
Stack.setChannel(1);
close("Mask");
//run("Duplicate...", "title=final duplicate");		//Use this image for overlay when smoothing - NaNs will be removed
selectWindow("temp");

run("Split Channels");
intensityImage = "C1-temp";
lifetimeImage = "C2-temp";

//prepare thresholded image
selectWindow(intensityImage);
run("Duplicate...", "title=forThreshold duplicate");
run("Median...", "radius="+medianRadius);
run("8-bit");
run("Auto Local Threshold", "method=Mean radius="+autoThresholdRadius+" parameter_1="+autoThresholdParameter1+" parameter_2=0 white");
run("Watershed");

//create table tp hold data
lifetimeTable = "Lifetime_Data";
Table.create(lifetimeTable);

//multiply lifetime with intensity (for normalization)
imageCalculator("Multiply create 32-bit stack", lifetimeImage, intensityImage);
rename("lifetime * intensity");


for (i = 0; i < nrCells; i++) {
	selectWindow(originalImage);
	run("To ROI Manager");
	//get cell ROIs from overlay and place back as overlay
	run("From ROI Manager");
	selectWindow("forThreshold");
	
	//Detect and rename peroxisomes in cell i+1
	roiManager("select", i);
	roiManager("reset");
	run("Analyze Particles...", "size="+minPeroxisomeSize+"-Infinity pixel display add");
	roiManager("Set Color", "red");
	for (p = 0; p < roiManager("count"); p++) {
		roiManager("select",p);
		roiManager("rename","peroxisome_"+i+1+","+p+1);
	}
	roiManager("Deselect");
	
	//measure intensities
	selectWindow(intensityImage);
	showStatus("Measuring intensities...");
	roiManager("multi-measure measure_all");
	selectWindow("Results");
	intensityData = Table.getColumn("Mean", "Results");	//Get the peroxisome intensities for this cell.
	areaData = Table.getColumn("Area", "Results");		//Get the peroxisome areas for this cell. 
	Table.renameColumn("Mean", "Int_cell_"+i);
	
	//measure lifetimes times intensity
	selectWindow("lifetime * intensity");
	roiManager("deselect");
	showStatus("Measuring...");
	roiManager("multi-measure measure_all");
	selectWindow("Results");
	lifetimeTimesIntensityData = Table.getColumn("Mean", "Results");	//Get the lifetime data for this cell. +1 because the first headers is "".

	//Normalize lifetime with cell intensity and create tables and plot
	lifetimeData = DivideArrays(lifetimeTimesIntensityData,intensityData);	//divide by intensity at every frame to normalize
	lifetimeData = divideArraybyScalar(lifetimeData, 1000);					//convert from ps to ns.

	//Add data to table
	Table.setColumn("area_cell_"+i+1, areaData, lifetimeTable);
	Table.setColumn("intensity_cell_"+i+1, intensityData, lifetimeTable);
	Table.setColumn("lifetime_cell_"+i+1, lifetimeData, lifetimeTable);

	selectWindow(originalImage);
	run("From ROI Manager");
}

close(intensityImage);
close(lifetimeImage);
close("lifetime * intensity");
close("forThreshold");

//Retrieve all overlays as ROIs again
roiManager("reset");
selectWindow(originalImage);
run("To ROI Manager");
roiManager("Show None");

//overlayIntensitywithLifetime("final", 0, 50, minTau, maxTau, smoothOverlay);
overlayIntensitywithLifetime(originalImage, 0, maxInt, minTau, maxTau, smoothOverlay);
setBatchMode("show");
roiManager("Show All without labels");

setBatchMode(false);

//Trying to close the Results window; somehow doesn't work in the macro.
//run("Clear Results");
//selectWindow("Results");
//run("Close");
close("Results");


//Plot for each cell the lifetime vs intensity of all peroxisomes 
Plot.create("Plot - "+originalImage, "intensity", "lifetime");
legendString = "";
for (i = 0; i < nrCells; i++) {
	Plot.add("Circle", Table.getColumn("intensity_cell_"+i+1, lifetimeTable), Table.getColumn("lifetime_cell_"+i+1, lifetimeTable));
	Plot.setStyle(i, colors[i%colors.length]+",white,4,Dot");
	legendString = legendString + "cell "+ i+1 +"\n";
}
Plot.setLegend(legendString, "Top-Right");
Plot.setFrameSize(600, 400);
//Plot.setLimitsToFit();
Plot.setLimits(0, NaN, minTau, maxTau);
Plot.show();

saveAs("tiff", outputFolder + File.separator + "Plot of "+originalImage);
Table.save(outputFolder + File.separator + "LifetimeData_"+originalImage+ ".tsv");

restoreSettings;

//--------------------------------------------------------------------

//Overlay intensity with lifetime. Input image has to be 2-channels: (Intensity, Lifetime)
function overlayIntensitywithLifetime(image, minInt, maxInt, minTau, maxTau, smooth) {
	selectWindow(image);
	run("Duplicate...", "title=Intensity duplicate channels=1");
	run("16-bit");	//necessary for 'Apply LUT' later
	run("Grays");
	setMinAndMax(minInt, maxInt);
	run("Apply LUT", "stack");
	
	selectWindow(image);
	run("Duplicate...", "title=Lifetime duplicate channels=2");
	run("Remove Overlay");
	run("32-bit");
	if(smooth==true) {
		//run("Remove NaNs...", "radius="+smoothRadius);
		run("Mean...", "radius="+smoothRadius+" stack");
	}
	run("Divide...", "value=1000 stack");
	setMinAndMax(minTau, maxTau);
	run("Physics Black");
	run("Calibration Bar...", "location=[Upper Right] fill=Black label=White number=5 decimal=2 font=12 zoom=1 overlay");
	Overlay.copy;
	run("RGB Color");
	run("Split Channels");
	
	imageCalculator("Multiply 32-bit stack", "Lifetime (red)", "Intensity");
	rename("Red");
	imageCalculator("Multiply 32-bit stack", "Lifetime (green)", "Intensity");
	rename("Green");
	imageCalculator("Multiply 32-bit stack", "Lifetime (blue)", "Intensity");
	rename("Blue");
	run("Merge Channels...", "c1=Red c2=Green c3=Blue");
	rename(image+"_overlay");
	Overlay.paste;
	close("Intensity");
	close("Lifetime (red)");
	close("Lifetime (green)");
	close("Lifetime (blue)");
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
