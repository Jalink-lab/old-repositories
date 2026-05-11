#@ Integer (label = "Maximum ring diameter (pixels)", style = "spinner", value=100) max_diameter
#@ Integer (label = "Width of the ring selection (pixels)", style = "spinner", value=1) width
#@ Integer (label = "Spacing between consecutive ring selections", style = "spinner", value=2) spacing

if(selectionType!=10) exit("Create a (multi)point selection first");
run("Set Measurements...", "area mean standard min perimeter integrated median redirect=None decimal=3");
run("Clear Results");

roiManager("Add");	//Add the selection to the ROI manager
getSelectionCoordinates(xpoints, ypoints);
for(n=0;n<xpoints.length;n++) {
	for(i=1;i<max_diameter/spacing;i++) {
		makeOval(xpoints[n]-(i*spacing/2),ypoints[n]-(i*spacing/2),i*spacing,i*spacing);
		run("Make Band...", "band="+width);
		run("Measure");
	}
}
roiManager("Select", roiManager("count")-1);	//Select and delete the selection in the ROI manager
roiManager("Delete");
run("Restore Selection");