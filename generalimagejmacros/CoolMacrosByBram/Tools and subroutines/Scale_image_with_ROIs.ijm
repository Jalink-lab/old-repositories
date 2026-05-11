scale = 2;

setBatchMode(true);
run("Scale...", "x="+scale+" y="+scale+" interpolation=None average process create");

showStatus("Scaling ROIs...");
for(i=0;i<roiManager("count");i++) {
	if(i%1000==0) showProgress(i/roiManager("count"));
	roiManager("Select",i);
	run("Scale... ", "x="+scale+" y="+scale);
	roiManager("update");
}
roiManager("show all without labels");
setBatchMode("show");