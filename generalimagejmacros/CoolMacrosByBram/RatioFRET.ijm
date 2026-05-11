#@ File (label = "Input file", style = "file") input
#@ Integer (label = "Donor channel", value = 1) chDonor
#@ Integer (label = "Acceptor channel", value = 2) chAcceptor
#@ Float (label = "Median filter radius", value = 1) medianRadius
#@ Boolean (label = "Subtract background (rolling ball)?", value = true) bgsubtr
#@ Boolean (label = "Automatic threshold?", value = true) autoThreshold
#@ Boolean (label = "Normalize ratio to 1?", value = true) normalizeRatio
#@ Integer (label = "with baseline length (frames)", value = 10) baselineLength
#@ Boolean (label = "Create overlay with intensity?", value = true) createOverlay
#@ Float (label = "Smooth in XY with radius (pixels)", value = 1) smoothXY
#@ Float (label = "Smooth in time with radius (frames)", value = 1) smoothZ
#@ Float (label = "Minimum ratio value", value = 0) minRatio
#@ Float (label = "Minimum ratio value", value = 5) maxRatio
#@ Integer (label = "Maximum displayed intensity", value = 100) maxInt

#@ Boolean (label = "Add scale bar?", value=true) scaleBar
#@ Boolean (label = "Add calibration bar?", value=true) calibrationBar
#@ Boolean (label = "Add time stamp?", value=true) timeStamp

scaleBarSize = 50;


run("Close All");
open(input);
image = getTitle();
frameInterval = Stack.getFrameInterval();

run("Duplicate...", "duplicate channels="+chDonor);
rename("Donor");
if (bgsubtr == true) run("Subtract Background...", "rolling=50 sliding stack");	//50 pixels. TO DO: put in dialog
selectWindow(image);
run("Duplicate...", "duplicate channels="+chAcceptor);
rename("Acceptor");
if (bgsubtr == true) run("Subtract Background...", "rolling=50 sliding stack");	//50 pixels. TO DO: put in dialog

imageCalculator("Divide create 32-bit stack", "Donor","Acceptor");
rename("Ratio");
changeValues(NaN,NaN,0);

imageCalculator("Add create 32-bit stack", "Acceptor","Donor");
rename("Combined_intensity");
run("Grays");
run("Duplicate...", "title=mask_to_be duplicate");

if (medianRadius > 0) run("Median...", "radius="+medianRadius+" stack");
setAutoThreshold("Otsu dark stack");
if (autoThreshold == false) {
	run("Threshold...");
	waitForUser("Adjest threshold if necessary. Press OK to continue");
	run("Convert to Mask", "method=Otsu background=Dark black");	//Threshold not calculated
}
else run("Convert to Mask", "method=Otsu background=Dark calculate black");	//Autothreshold calculated for every slice
run("Fill Holes", "stack");
run("32-bit");
setThreshold(128,255);
run("NaN Background", "stack");
run("Divide...", "value=255 stack");
setMinAndMax(0,1);
rename("Mask");
imageCalculator("Multiply create 32-bit stack", "Ratio","Mask");
rename("Ratio_masked");
setMinAndMax(minRatio, maxRatio);
run("Physics Black");
run("Set... ", "zoom=200");

if(normalizeRatio==true) {
	run("Set Measurements...", "mean standard redirect=None decimal=3");
	total = 0;
	for(i=1;i<=baselineLength;i++) {
		Stack.setFrame(i);
		List.setMeasurements;
		total = total + List.getValue("Mean");
	}
	mean = total / baselineLength;
	run("Divide...", "value="+mean+" stack");
}

//Normalize unmasked ratio
selectWindow("Ratio");
run("Divide...", "value="+mean+" stack");
run("Mean 3D...", "x="+smoothXY+" y="+smoothXY+" z="+smoothZ); //smooth ratio in time
run("Physics Black");
setMinAndMax(minRatio, maxRatio);

//Overlay intensity
if(createOverlay == true) {
	run("RGB Color");
	run("Split Channels");
	selectWindow("Combined_intensity");
	run("Mean 3D...", "x=0 y=0 z=2"); //smooth intensity only in time

//	run("Divide...", "value=64 stack");
	run("8-bit");
	setMinAndMax(0,maxInt);	//brightness of intensity channel
	run("Apply LUT", "stack");

	imageCalculator("Multiply 32-bit stack", "Combined_intensity","Ratio (red)");
	rename("Red");
	imageCalculator("Multiply 32-bit stack", "Combined_intensity","Ratio (green)");
	rename("Green");
	imageCalculator("Multiply 32-bit stack", "Combined_intensity","Ratio (blue)");
	rename("Blue");
	run("Merge Channels...", "c1=Red c2=Green c3=Blue");
	rename("Ratio (RGB)");
	run("Set... ", "zoom=200");

	if(scaleBar) run("Scale Bar...", "width="+scaleBarSize+" height=3 font=14 color=White background=None location=[Lower Right] bold label");
	if(timeStamp) run("Label...", "format=0 starting=0 interval="+d2s(frameInterval,0)+" x=10 y=30 font=14 text=sec");

	close("Ratio (red)");
	close("Ratio (green)");
	close("Ratio (blue)");

	if(calibrationBar) {
		selectWindow("Ratio_masked");
		run("Calibration Bar...", "location=[Upper Right] fill=Black label=White number=4 decimal=1 font=12 zoom=1 overlay");
		Overlay.copy;
		selectWindow("Ratio (RGB)");
		Overlay.paste;
	}
	selectWindow("Ratio_masked");
	run("Grays");

	selectWindow("Ratio (RGB)");
	run("Flatten", "stack");
	doCommand("Start Animation [\\]");
}
