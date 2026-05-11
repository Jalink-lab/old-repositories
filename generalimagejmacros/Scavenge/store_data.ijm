// open file
run("Close All");
run("Boats (356K)");
// add a few rois
roiManager("reset") 
makeRectangle(161, 143, 55, 71);
roiManager("Add");
makeRectangle(386, 263, 82, 62);
roiManager("Add");
makeRectangle(506, 163, 79, 67);
roiManager("Add");
makeRectangle(215, 318, 43, 83);
roiManager("Add");
makeRectangle(378, 479, 94, 54);
roiManager("Add");
makeRectangle(568, 400, 87, 73);
roiManager("Add");

// measure
run("Clear Results");
roiManager("Measure");
table.create("myResults");
table.set
Table.update;
test = List.setMeasurements;

print(getResult("Mean", 0));