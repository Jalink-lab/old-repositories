macro "Select ROI [r]" {
	setBatchMode(true);
	foundROI=-1;
	getCursorLoc(x, y, z, modifiers);
	makePoint(x, y, "small red hybrid");
	for(i=0;i<roiManager("count");i++) {
		roiManager("select",i);
		if(Roi.contains(x, y)==1) {
			foundROI=i;
			i=roiManager("count");	//break from the loop
		}
	}
	setBatchMode(false);
	if(foundROI>0) {
		roiManager("select",foundROI);
		print("ROI "+foundROI+" selected");
	}
	else print("No ROI at this location");
}