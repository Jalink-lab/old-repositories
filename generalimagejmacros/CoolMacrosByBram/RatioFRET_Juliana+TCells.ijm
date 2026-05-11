#@ File (label = "Input file", style = "file") input
#@ Integer (label = "Donor channel", value = 1) chDonor
#@ Integer (label = "Acceptor channel", value = 2) chAcceptor
#@ Integer (label = "T-cell channel", value = 3) chTCells
#@ Float (label = "Median filter radius", value = 1) medianRadius
#@ Boolean (label = "Automatic threshold?", value = true) autoThreshold
#@ Boolean (label = "Normalize ratio to 1?", value = true) normalizeRatio
#@ Integer (label = "with baseline length (frames)", value = 10) baselineLength
#@ Boolean (label = "Create overlay with intensity?", value = true) createOverlay


run("Close All");
open(input);
image = getTitle();
run("Duplicate...", "duplicate channels="+chDonor);
rename("Donor");
selectWindow(image);
run("Duplicate...", "duplicate channels="+chAcceptor);
rename("Acceptor");
selectWindow(image);
run("Duplicate...", "duplicate channels="+chTCells);
rename("TCells");
run("Grays");

imageCalculator("Divide create 32-bit stack", "Acceptor","Donor");
rename("Ratio");
changeValues(NaN,NaN,0);

imageCalculator("Add create 32-bit stack", "Acceptor","Donor");
rename("Combined_intensity");
run("Grays");
run("Duplicate...", "title=mask_to_be duplicate");

run("Median...", "radius="+medianRadius+" stack");
setAutoThreshold("Otsu dark stack");
if(autoThreshold==false) {
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
setMinAndMax(0,5);
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
run("Mean 3D...", "x=0 y=0 z=2"); //smooth ratio in time
setMinAndMax(0,4);
run("Physics Black");

//Overlay intensity
if(createOverlay == true) {
	run("RGB Color");
	run("Split Channels");
	selectWindow("Combined_intensity");
	run("Mean 3D...", "x=0 y=0 z=2"); //smooth intensity in time

//	run("Divide...", "value=64 stack");
	run("8-bit");
	setMinAndMax(0,50);	//brightness of intensity channel
	run("Apply LUT", "stack");
	imageCalculator("Multiply 32-bit stack", "Combined_intensity","Ratio (red)");
	rename("Red");
	imageCalculator("Multiply 32-bit stack", "Combined_intensity","Ratio (green)");
	rename("Green");
	imageCalculator("Multiply 32-bit stack", "Combined_intensity","Ratio (blue)");
	rename("Blue");
	run("Merge Channels...", "c1=Red c2=Green c3=Blue c4=TCells");
	if(is("composite"))	run("RGB Color", "frames keep");
	
	rename("Ratio (RGB)");
	run("Set... ", "zoom=200");
	
	close("Ratio (red)");
	close("Ratio (green)");
	close("Ratio (blue)");
}
