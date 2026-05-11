// ImageJ macro to calculate the Radial Distribution Function (RDF) of particle centers
//
// Version 2011-08-22 
//
// Input: Binary or 8-bit input image/stack with dark particles on light background.
// Grayscale/RGB images are OK as long as "Find Maxima" works reliably on them.
// For binary images/stacks, the macro does not care whether "black background" 
// is selected in Process>Binary>Options.
//
// Output: Normalized RDF plot with distance in pixels. For stacks the mean is plotted. 
//
// Known Issues, Updates and Examples at:
// http://imagejdocu.tudor.lu/doku.php?id=macro:radial_distribution_function
//
// Requirements: A working install of "Radial Profile" plugin is required. Get it at
// http://rsb.info.nih.gov/ij/plugins/radial-profile.html
//
// Limitations:
// - Particle positions are rounded to full pixel nearest to particle intensity maximum
// - RDF output distances are in pixels, irrespective of any spatial calibration of the image
// - RDF range is 0.3x the smallest dimension of the image
// - Particles touching the edge will be ignored; this will limit the accuracy
//    if the particles are not much smaller than the image size.
// - Do not extend the image size for avoiding edge effects; the macro takes care of this.
//
//////////////////////////////////////////////////////////////////////////////////

macro "Radial Distribution Function [f5]" {
	run("Select None");
	doStack=false;
	//User dialog
	Dialog.create('RDF Options');
	Dialog.setInsets(0,0,0)
	Dialog.addMessage("Radial Distribution Function Macro \nby Michael Schmid & Ajay Gopal \n(v.2011-08-21)");
	if (nSlices()>1) {
		Dialog.addMessage("Selected file is a stack. \nUncheck below to analyze \nonly the current slice.");
		Dialog.addCheckbox("Use all slices in stack?", true);
	}
	Dialog.addMessage("Particle Detection Noise Threshold \nHint: test image/s first with \nImageJ>Process>Find Maxima \nto verify that below threshold \ngives accurate particle centers.");
	Dialog.addNumber("     Noise Threshold", 10);
	Dialog.addMessage("Default output is RDF plot with \noptions to list, save & copy data. \nCheck below to output extra \nwindow with RDF data table.");
	Dialog.addCheckbox("Output RDF data table ", false);
	Dialog.show;
	 //Preliminary checks
	if (nSlices()>1) {doStack = Dialog.getCheckbox;}
	noiseThr = Dialog.getNumber;
	showList = Dialog.getCheckbox;
	setBatchMode(true);
	firstSlice=getSliceNumber();
	lastSlice=getSliceNumber();
	if (doStack) {
		firstSlice=1;
		lastSlice=nSlices();
	}
	width=getWidth;
	height=getHeight;
	//maxRadius may be modified, should not be larger than 0.3*minOf(width, height);
	maxRadius=0.3*minOf(width, height);
	minFFTsize=1.3*maxOf(width, height);
	title=getTitle();
	size=4;
	while(size<minFFTsize) size*=2;
	//Main processing loop
	for (slice=firstSlice; slice<=lastSlice; slice++) {
		//Make autocorrelation of particle positions
		if (doStack) setSlice(slice);
		run("Find Maxima...", "noise="+noiseThr+" output=[Maxima Within Tolerance] dark exclude");  
		tempID=getImageID();
		tempTitle="temp-"+random();
		rename(tempTitle);
		run("Canvas Size...", "width="+ size+" height="+ size+" position=Center zero");
		run("FD Math...", "image1=["+tempTitle+"] operation=Correlate image2=["+tempTitle+"] result=AutoCorrelation do");
		psID=getImageID();
		selectImage(tempID);
		close();
		//Make autocorrelation reference to correct finite image size effects
		newImage("frame", "8-bit White", width, height, 1);
		run("Set...", "value=255");
		tempID=getImageID();
		rename(tempTitle);
		run("Canvas Size...", "width="+ size+" height="+ size+" position=Center zero");
		run("FD Math...", "image1=["+tempTitle+"] operation=Correlate image2=["+tempTitle+"] result=AutoCorrReference do");
		refID=getImageID();
		imageCalculator("Divide", psID,refID);
		selectImage(refID);
		close();
		selectImage(tempID);
		close();
		//Prepare normalized power spectrum for radial averaging
		selectImage(psID);
		makeRectangle(size/2, size/2, 1, 1);
		run("Set...", "value=0");
		run("Select None");
		circleSize=2*floor(maxRadius)+1;
		run("Specify...", "width="+circleSize+" height="+circleSize+" x="+(size/2+0.5)+" y="+(size/2+0.5)+" oval centered");
		getRawStatistics(nPixels, mean);
		run("Select None");
		run("Divide...", "value="+mean);
		run("Specify...", "width="+circleSize+" height="+circleSize+" x="+(size/2+0.5)+" y="+(size/2+0.5)+" oval centered");
		run("Radial Profile", "x="+(size/2+0.5)+" y="+(size/2+0.5)+" radius="+floor(maxRadius)-1);
		rename("RDF of "+title);
		rdfID=getImageID(); 
		selectImage(psID); 
		close();
		//Averaging of RDFs for stacks 
		if (doStack) {
			selectImage(rdfID);   
			Plot.getValues(x, y);
			if (slice==firstSlice) ySum = newArray(y.length);
			for (i=0; i<y.length; i++)
			ySum[i]+ = y[i] / lastSlice;
			close();
		}
	}//End Processing Loop	

	//Create output plots with annotated titles and options
	if (doStack) {
		Plot.create("RDF of "+title+" (stack)", "Distance (pixels)", "RDF", x, ySum);
		if (showList) {
			run("Clear Results");
			for (i=0; i<x.length; i++) {
				setResult("R", i, x[i]);
				setResult("RDF", i, ySum[i]);
			}
			updateResults();
		}
	} 
	else {
		selectImage(rdfID);
		Plot.getValues(x, y);
		Plot.create("RDF of "+title+" (slice"+lastSlice+")", "Distance (pixels)", "RDF", x, y);
		if (showList) {
			run("Clear Results");
			for (i=0; i<x.length; i++) {
				setResult("R", i, x[i]);
				setResult("RDF", i, y[i]);
			}
			updateResults();
		}
		close();		
	}//End Output
	setBatchMode("exit and display");// Comment this out if you get duplicate RDF outputs
} //End Macro