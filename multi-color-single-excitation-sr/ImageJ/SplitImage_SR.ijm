#@ File (label = "input file", style = "file") inputPath
#@ Integer(label = "Cross-correlation stack reduction", value = 10) ccReduction
#@ Integer(label = "Cross-correlation upscale", value = 2) ccScale
#@ Integer(label = "Temporal median window", value = 501) TMWindow
#@ Integer(label = "Offset after temporal median background subtraction", value = 1000) offset

showMerged=true;

run("Close All");

fileName = substring(File.getName(inputPath),0,lastIndexOf(File.getName(inputPath), "."));
inputFolder = File.getParent(inputPath) + File.separator;
outputFolder = inputFolder + "output" + File.separator;
if(!File.exists(outputFolder)) File.makeDirectory(outputFolder);

open(inputPath);
rename(fileName);

//split
Stack.getDimensions(width, height, channels, slices, frames);
if(slices>1){
	print("Re-ordering hyperstack...");
	run("Re-order Hyperstack ...", "channels=[Channels (c)] slices=[Frames (t)] frames=[Slices (z)]");
}
Stack.getDimensions(width, height, channels, slices, frames);
run("Enhance Contrast", "saturated=0.35");

makeRectangle(0, 0, width/2, height);
run("Duplicate...", "duplicate title=["+fileName+"_Left]");

selectWindow(fileName);
makeRectangle(width/2, 0, width/2, height);
run("Crop");
rename(fileName+"_Right");
if (showMerged) {
	run("Merge Channels...", "c1="+fileName+"_Left c2="+fileName+"_Right create keep");
	rename(fileName+"_Merged");
}

//substack (reduce image, no need to correlate all frames)
selectWindow(fileName+"_Left");
run("Duplicate...", "duplicate title=Left_Image_reduced");
run("Reduce...", "reduction="+ccReduction);
//run("Grouped Z Project...", "projection=[Sum Slices] group="+ccReduction);	//Use this one in stead of 'reduce' in case the image quality is really bad
//rename("Left_Image_reduced");

selectWindow(fileName+"_Right");
run("Duplicate...", "duplicate title=Right_Image_reduced");
run("Reduce...", "reduction="+ccReduction);
//run("Grouped Z Project...", "projection=[Sum Slices] group="+ccReduction);
//rename("Right_Image_reduced");

//upscale
selectWindow("Left_Image_reduced");
run("Scale...", "x="+ccScale+" y="+ccScale+" interpolation=Bilinear average process create");
rename("Left_Image_reduced_scaled");
close("Left_Image_reduced");

selectWindow("Right_Image_reduced");
run("Scale...", "x="+ccScale+" y="+ccScale+" interpolation=Bilinear average process create");
rename("Right_Image_reduced_scaled");
close("Right_Image_reduced");

//cross correlate the-reduced-stacks frame by frame and add the result
Stack.getDimensions(width, height, channels, slices, frames);
setBatchMode(true);
print(frames);
for (i=1;i<=frames;i++){
	selectWindow("Left_Image_reduced_scaled");
	Stack.setFrame(i);
	selectWindow("Right_Image_reduced_scaled");
	Stack.setFrame(i);
	run("FD Math...", "image1=Right_Image_reduced_scaled operation=Correlate image2=Left_Image_reduced_scaled result=Result do");
	if (i==1){
		rename("Cross_Corr");
	} else {
		imageCalculator("Add 32-bit", "Cross_Corr","Result");
		close("Result");
	}
}
close("Left_Image_reduced");
close("Right_Image_reduced");
//get maximum pixel and return shift
getDimensions(width_scaled, height_scaled, channels, slices, frames);
getStatistics(area, mean, min, max, std, histogram);
x=0;y=0;
while (getPixel(x, y)!=max) {
	x=x+1;
	if (x>width_scaled) {x=0;y=y+1;}
}
print("Cross-correlation center (scaled up) at pixel x="+x+" ; y="+y);

setBatchMode("show");
run("Fire");
makePoint(x, y, "small cyan hybrid");
waitForUser("Ok, this is really poor, but if the point selection is not at the center of the cross correlation, please move it to the correct position and press OK.");
getSelectionCoordinates(xpoints, ypoints);
x=xpoints[0]; y=ypoints[0];
print("Updated cross-correlation center (scaled up) at pixel x="+x+" ; y="+y);

close("Cross_Corr");

x = -(x-width_scaled/2)/ccScale;
y = -(y-height_scaled/2)/ccScale;
print("Translating Right image with: x="+x+" ; y="+y);

//transform Right Image, fill zeros with offset and overlay
selectWindow(fileName+"_Right");
run("Translate...", "x="+x+" y="+y+" interpolation=Bilinear stack");

if (showMerged){
	run("Merge Channels...", "c1="+fileName+"_Left c2="+fileName+"_Right create keep");
	rename(fileName+"_Shifted_Merged");
}
setBatchMode("show");
setBatchMode(false);	//necessary, because otherwise the wrong image is selected (?)

//Save images
selectWindow(fileName+"_Right");
saveAs("Tiff", outputFolder + fileName + "_Right.tif");
selectWindow(fileName+"_Left");
saveAs("Tiff", outputFolder + fileName + "_Left.tif");


//temporal median filter
selectWindow(fileName+"_Right.tif");
run("Temporal Median Background Subtraction", "window="+TMWindow+" offset="+offset);
selectWindow("MEDFILT_"+fileName+"_Right.tif");
rename(fileName+"_Right_TMBS");
for(i=0;i<frames;i++) {
	Stack.setFrame(i+1);
	changeValues(0, 0, offset);	//Fill empty values
}
Stack.setFrame(1);
run("Enhance Contrast", "saturated=0.35");
selectWindow(fileName+"_Left.tif");
run("Temporal Median Background Subtraction", "window="+TMWindow+" offset="+offset);
selectWindow("MEDFILT_"+fileName+"_Left.tif");
rename(fileName+"_Left_TMBS");
run("Enhance Contrast", "saturated=0.35");

//Save TMBS Images
selectWindow(fileName+"_Right_TMBS");
saveAs("Tiff", outputFolder + fileName + "_Right_TMBS.tif");
selectWindow(fileName+"_Left_TMBS");
saveAs("Tiff", outputFolder + fileName + "_Left_TMBS.tif");

exit;

//Thunderstorm fit settings
ts_filter = "Wavelet filter (B-Spline)";
ts_scale = 2;
ts_order = 3;
ts_detector = "Local maximum";
ts_connectivity = "8-neighbourhood";
ts_threshold = "1*std(Wave.F1)";
ts_estimator = "PSF: Integrated Gaussian";
ts_sigma = 1.2;
ts_fitradius = 5;
ts_method = "Weighted Least squares";
ts_full_image_fitting = false;
ts_mfaenabled = false;
ts_renderer = "No Renderer";
ts_magnification = 10;
ts_colorize = false;
ts_threed = false;
ts_shifts = 2;
ts_repaint = 50;
//Thunderstorm save settings
ts_floatprecision = 5;

run("Camera setup", "readoutnoise=0.0 offset=1000.0 quantumefficiency=0.7 isemgain=false photons2adu=3.6 pixelsize=101.56");

selectWindow(fileName + "_Right_TMBS.tif");
//run("Temporal Median Background Subtraction", "window=201 offset=100");
outputcsv = outputFolder + fileName + "_Right.csv";
run("Run analysis", "filter=["+ts_filter+"] scale="+ts_scale+" order="+ts_order+" detector=["+ts_detector+"] connectivity=["+ts_connectivity+"] threshold=["+ts_threshold+
	  "] estimator=["+ts_estimator+"] sigma="+ts_sigma+" fitradius="+ts_fitradius+" method=["+ts_method+"] full_image_fitting="+ts_full_image_fitting+" mfaenabled="+ts_mfaenabled+
	  " renderer=["+ts_renderer+"] magnification="+ts_magnification+" colorize="+ts_colorize+" threed="+ts_threed+" shifts="+ts_shifts+" repaint="+ts_repaint);
run("Export results", "floatprecision="+ts_floatprecision+" filepath=["+ outputcsv + "] fileformat=[CSV (comma separated)] sigma=true intensity=true offset=true saveprotocol=false x=true y=true bkgstd=true id=true uncertainty_xy=true frame=true");

selectWindow(fileName + "_Left_TMBS.tif");
//run("Temporal Median Background Subtraction", "window=201 offset=100");
outputcsv = outputFolder + fileName + "_Left.csv";
run("Run analysis", "filter=["+ts_filter+"] scale="+ts_scale+" order="+ts_order+" detector=["+ts_detector+"] connectivity=["+ts_connectivity+"] threshold=["+ts_threshold+
	  "] estimator=["+ts_estimator+"] sigma="+ts_sigma+" fitradius="+ts_fitradius+" method=["+ts_method+"] full_image_fitting="+ts_full_image_fitting+" mfaenabled="+ts_mfaenabled+
	  " renderer=["+ts_renderer+"] magnification="+ts_magnification+" colorize="+ts_colorize+" threed="+ts_threed+" shifts="+ts_shifts+" repaint="+ts_repaint);
run("Export results", "floatprecision="+ts_floatprecision+" filepath=["+ outputcsv + "] fileformat=[CSV (comma separated)] sigma=true intensity=true offset=true saveprotocol=false x=true y=true bkgstd=true id=true uncertainty_xy=true frame=true");
run("Close All");




