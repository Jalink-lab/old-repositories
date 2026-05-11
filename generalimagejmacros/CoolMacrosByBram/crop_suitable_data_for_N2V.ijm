@Integer(label = "nr of crops to generate", value=1000) nrCrops
@Integer(label = "X size", value=128) sizeX
@Integer(label = "Y size", value=128) sizeY
@String (choices={"Mean", "StdDev"}, style="radioButtonHorizontal") metric
@Integer(label = "should be above", value=2) minMeasurement


run("Clear Results");

original = getTitle();
getDimensions(width, height, channels, slices, frames);
Stack.getPosition(channel, slice, frame);

setBatchMode("hide");
n=0;
for (i = 0; i < nrCrops; i++) {
	selectWindow(original);
	showProgress(i/nrCrops);
	currentSlice = floor(random*slices)+1;
	currentFrame = floor(random*frames)+1;
	currentX = random*(width-sizeX);
	currentY = random*(width-sizeY);

	Stack.setPosition(channel, currentSlice, currentFrame);
	//setPixel(currentX, currentY, 255);
	makeRectangle(currentX, currentY, sizeX, sizeY);

	List.setMeasurements();
	mean = List.getValue(metric);
	if(mean<minMeasurement) {
		i=i-1;
		n++;
	}
	else {
		//run("Measure");
		run("Duplicate...", "title=crop_"+i+1);
	}
}
selectWindow(original);
run("Select None");
run("Images to Stack", "name=Stack title=crop use");
setBatchMode("exit and display");
print("Made "+nrCrops+" crops with "+metric+" > "+minMeasurement+" ("+n+" tries).");
