/* Macro for selecting and aligning ROIs in a timelapse.
 * Input files should be cropped timelapse movies of tracked cells/nuclei.
 * 
 * Workflow:
 * - Nuclei are segmented, and in each frame, the ROI closest to the center of the image is kept 
 * - Option to edit the ROIs, e.g. using the interactive wand tool.
 * - 'Registration': the centroid of each ROI is translated to the center of the image.
 *
 * Required Fiji Update sites: CLIJ, CLIJ2, SCF MPI CBG
 * 
 * Author: Bram van den Broek (b.vd.broek@nki.nl), Netherlands Cancer Institute, May 2020
 */

#@ File[] (label = "Add files", style="File") files

#@ Boolean (label = "Equalize intensity of all frames (bleach correction)", value = true) bleachCorrection
#@ Integer (label = "Median filter radius for segmentation (0 = no filter)", value=3) medianRadius
#@ Float (label = "Threshold window (% field of view)", description="Only a center square of the image will be used for determining the auto threshold", min=0, max=1, value=0.5) thresholdWindow
#@ Boolean (label = "Use Automatic threshold for nuclei segmentation", value = true) autoThreshold
#@ String (label = "Autothreshold method", choices = {"Default", "Huang", "Intermodes", "IsoData", "IJ_IsoData", "Li", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen"}, style="list") thresholdMethod
#@ Boolean (label = "Recalculate threshold for each frame", value = true) calculate_threshold
#@ Boolean (label = "Use StarDist instead for initial nuclear segmentation", value = true) StarDist
#@ Float (label = "Minimum nucleus size", style="slider", min=0, max=100, value=4) Min_Nucleus_Size
#@ Float (label = "Maximum nucleus size", style="slider", min=0, max=100, value=40) Max_Nucleus_Size
#@ Boolean (label = "Use watershed to separate touching nuclei", value = false) watershed

exclude_edges = false;	//Exclude on edges; not necessary.


run("CLIJ2 Macro Extensions", "cl_device=");
Ext.CLIJ2_clear();
run("Set Measurements...", "area mean standard centroid stack redirect=None decimal=3");
setBatchMode(true);

for(n=0; n<files.length; n++) {
	run("Close All");
	run("Clear Results");
	roiManager("Reset");
	open(files[n]);
	
	original = getTitle();
	setBatchMode("show");
	getDimensions(width, height, channels, slices, frames);
	getPixelSize(unit, pw, ph, pd);
	
	if(bleachCorrection==true) equalize_intensities(original);
	else run("Duplicate...", "duplicate");
	rename("to_be_segmented");
	segment_nuclei("to_be_segmented");
	select_single_nucleus_per_frame();
	refine_segmentation("intensity_equalized_filtered");
	center_cells_with_ROIs();

	saveDir = File.directory + File.separator + "Analyzed" + File.separator;
	if(!File.exists(saveDir)) File.makeDirectory(saveDir);
	saveAs("Tiff", saveDir + File.nameWithoutExtension + "_analyzed");
	roiManager("save", saveDir + File.nameWithoutExtension + "_ROIset.zip");
}
run("Close All");
showMessage("Finished!");



//-------- Functions ----------


function equalize_intensities(image) {
	Ext.CLIJ2_push(image);
	reference_slice = 1.0;
	Ext.CLIJ2_equalizeMeanIntensitiesOfSlices(image, image_equalized, reference_slice);
	Ext.CLIJ2_pull(image_equalized);
	Ext.CLIJ2_clear();
	//run("Re-order Hyperstack ...", "channels=[Channels (c)] slices=[Frames (t)] frames=[Slices (z)]");
	run("Properties...", "channels="+channels+" slices="+slices+" frames="+frames+" unit="+unit+" pixel_width="+pw+" pixel_height="+ph+" voxel_depth="+pd);
}


function segment_nuclei(image) {
//	run("Duplicate...", "title=segmented_nuclei duplicate");

	// equalize mean intensities of slices (bleach correction)
	rename("intensity_equalized");
	run("Properties...", "unit=pixels pixel_width=1 pixel_height=1 voxel_depth=1.0000000 frame=0 origin=0,0");
//	if(medianRadius>0) Ext.CLIJ2_median2DSphere(intensity_equalized, intensity_equalized_filtered, medianRadius, medianRadius);
	if(medianRadius>0) run("Median...", "radius="+medianRadius+" stack");
	rename("intensity_equalized_filtered");
//	run("Duplicate...", "title=nuclei_before_segmentation duplicate");
	resetMinAndMax();
	selectWindow("intensity_equalized_filtered");
	resetMinAndMax();
/*
	//Dialog - replaced by script parameters
	thresholdList = getList("threshold.methods");
	Dialog.createNonBlocking("Options");
	Dialog.addCheckbox("Automatic threshold", true);
	Dialog.addChoice("AutoThreshold method", thresholdList, "Otsu");
	Dialog.show();
	autoThreshold = Dialog.getCheckbox();
	thresholdMethod = Dialog.getChoice();
*/
	if(StarDist != true) {
		run("Duplicate...", "title=Mask duplicate");
		if(thresholdWindow<1.0) {	//Clear image outside the threshold window
			makeRectangle((1-thresholdWindow)*width/2, (1-thresholdWindow)*height/2, thresholdWindow*width, thresholdWindow*height);
			run("Clear Outside", "stack");
		}
		if(autoThreshold==true)	{
			if (calculate_threshold==true) {
				resetThreshold();
				run("Convert to Mask", "method="+thresholdMethod+" background=Dark calculate black");	//threshold calculated for each frame
				//run("Convert to Mask", "method=Li background=Dark calculate black");
				resetThreshold();
			}
			else {
				run("Convert to Mask", "method=Otsu background=Dark black");		//Do not calculate threshold for each frame
				resetThreshold();
			}
		}
		else {
			setAutoThreshold("Li dark stack");
			run("Threshold...");
			selectWindow("Threshold");
			setBatchMode("show");
			waitForUser("Set threshold for segmentation of nuclei");
			run("Convert to Mask", "  black");
		}
		run("Fill Holes", "stack");
		if(watershed==true) run("Watershed", "stack");
		if(exclude_edges==true) run("Analyze Particles...", "size="+(Min_Nucleus_Size/pw)*(Min_Nucleus_Size/pw)*PI/4+"-"+(Max_Nucleus_Size/pw)*(Max_Nucleus_Size/pw)*PI/4+" circularity=0.20-1.00 show=Nothing display exclude add stack");
		else run("Analyze Particles...", "size="+(Min_Nucleus_Size/pw)*(Min_Nucleus_Size/pw)*PI/4+"-"+(Max_Nucleus_Size/pw)*(Max_Nucleus_Size/pw)*PI/4+" circularity=0.2-1.00 show=Nothing display add stack");
		if(roiManager("count")==0) {
			nuclei_found=false;
			print("No nuclei found!");
		}
		else print(roiManager("count")+" nuclei found");
		resetThreshold();
	}
	else if(StarDist == true){
		//downscale image for better results
		scale=4;
		run("Scale...", "x="+1/scale+" y="+1/scale+" interpolation=None average process create");
		rename("downscaled");
		run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'downscaled', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'4.0', 'percentileTop':'99.60000000000001', 'probThresh':'0.479071', 'nmsThresh':'0.3', 'outputType':'ROI Manager', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Stack', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");

		//upscale the ROIs
		showStatus("Scaling ROIs...");
		for(i=0;i<roiManager("count");i++) {
			showProgress(i/roiManager("count"));
			roiManager("Select",i);
			run("Scale... ", "x="+scale+" y="+scale);
			roiManager("update");
		}
		selectWindow("intensity_equalized_filtered");
		roiManager("Deselect");
		roiManager("show all without labels");
		roiManager("measure");

		//Create Mask for later use
		run("Duplicate...", "title=Mask duplicate");
	}
}



function select_single_nucleus_per_frame() {
	showStatus("Calculating central nucleus for each frame...");	//This is very fast, so you don't see it anyway.
	X = newArray(nResults);	//Array with centroids of nuclei
	Y = newArray(nResults);
	distance_to_center = newArray(nResults);
	X0 = getWidth/2;	//center coordinate of image
	Y0 = getHeight/2;
	ROI_indices = newArray(nResults);
	total=0;		//running total number of nuclei
	n=0;			//'ROI to delete' counter
	for(f=1;f<=frames;f++) {
		j=0;		//running number of nuclei per frame
		Array.fill(X, 0);	//reset arrays every frame
		Array.fill(Y, 0);
		Array.fill(distance_to_center, 9999);
		for(i=0;i<nResults;i++) {
			if(getResult("Slice", i)==f) {	//Check if this nucleus belongs to slice (frame) f
				X[j]=getResult("X", i);		//get centroid coordinates from measurements in segment_nuclei()
				Y[j]=getResult("Y", i);
				distance_to_center[j]=sqrt( (X[j]-X0)*(X[j]-X0) + (Y[j]-Y0)*(Y[j]-Y0));
				//print(f, distance_to_center[j]);
				j++;
				total++;
			}
		}
		rankPos = Array.rankPositions(distance_to_center);
		k=0;	//counter for this frame
		//print("j="+j);
		//print("total="+total);
		//print("position="+rankPos[0]);
		for(i=(total-j);i<total;i++) {	//run this loop only j times on the right ROIs
			if(k!=rankPos[0]) {
				ROI_indices[n]=i;	//ROIs to be deleted
				//print("deleting ROI nr "+i+1);
				n++;
			}
		k++;
		}
	}
	ROIs_to_delete = Array.trim(ROI_indices, n);	//trim array because it was created too long 
	print("Deleting "+ROIs_to_delete.length+" ROIs");
	roiManager("select", ROIs_to_delete);
	roiManager("Delete");
	roiManager("Set Color", "cyan");
}


function refine_segmentation(image) {
	selectWindow(image);
	Stack.setSlice(1);
	setBatchMode("show");
	roiManager("show all without labels");

	editingCompleted = false;

	//setTool("freehand");
	run("Interactive wand tool (2D)");
	showMessage("Start edting ROIs", "Scroll through the movie and redraw ROIs where segmentation is not correct\n(e.g. with the interactive wand tool)\nand press [t] to update it.\nPress [space] when finished.\n\nIf you forget to press [t], click on 'Show All' on the ROI Manager.");
	while(!isKeyDown("space")) {		//exit by pressing space bar
		if(roiManager("count")!=frames && roiManager("count")!=0) {	//change in the number of ROIs 
			run("Select None");
			Stack.getPosition(channel, slice, frame);
			roiManager("select",frame-1);
			roiManager("delete");
			roiManager("sort");
			roiManager("Show All");
			Stack.setPosition(channel, slice, frame+1);
		}
		else wait(50);
	}
	roiManager("Set Color", "cyan");
}


function center_cells_with_ROIs() {
	//Create mask from all ROIs in the ROI manager

	selectWindow("Mask");
	run("Select All");
	run("Clear", "stack");
	run("Select None");
	setForegroundColor(255, 255, 255);
	for (i = 0; i < roiManager("count"); i++) {
		roiManager("Select",i);
		run("Fill", "slice");
	}
	roiManager("Deselect");
	//Measure the center of mass on the binary masks
	run("Clear Results");
	roiManager("multi-measure");
	selectWindow(original);
	run("Select None");
	roiManager("Show None");
	for (i = 0; i < roiManager("count"); i++) {
		translate_X = -(getResult("X", i) - getWidth()/2);
		translate_Y = -(getResult("Y", i) - getHeight()/2);
		print("Translating "+translate_X+", "+translate_Y); 
		Stack.setFrame(i+1);
		run("Translate...", "x="+translate_X+" y="+translate_Y+" interpolation=None slice");
		roiManager("Select",i);
		Roi.getBounds(x, y, width, height);
		Roi.move(x + translate_X, y + translate_Y);
		roiManager("update");
		run("Select None");
	}
	run("From ROI Manager");
}
