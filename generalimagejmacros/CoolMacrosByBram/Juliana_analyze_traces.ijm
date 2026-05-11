#@ Float (label = "Minimum peak height", value = 0.4) tolerance
#@ Float (label = "Maximum displayed ratio in the plot", value = 3.5) maxRatio
#@ Integer (label = "Analyze until frame (-1 for all frames)", value = -1) endFrame

//Input file: ratio timetrace

saveSettings();
run("Plots...", "width=1000 height=250 font=16 draw draw_ticks minimum=0 maximum=0 interpolate sub-pixel");

//setBatchMode(true);

close("\\Others");
run("Clear Results");
print("\\Clear");

original = getTitle();
getDimensions(width, height, channels, slices, framesOriginal);
if(endFrame != -1) {
	run("Make Substack...", "  slices=1-"+endFrame);
	rename(original + " - frames 1-" + endFrame);
}
getDimensions(width, height, channels, slices, frames);
image = getTitle();
nRois = roiManager("count");
roiManager("Deselect");
roiManager("Remove Slice Info");
roiManager("show all with labels");

maxPos = newArray(99);
minPos = newArray(99);
maxAmp = newArray(99);
minAmp = newArray(99);
peakArea = newArray(99);

//setBatchMode(false);	//'Find Peaks' doesn't work in Batch Mode.

summaryTable = "Summary Table";
Table.create(summaryTable);

getLocationAndSize(x, y, width, height);
Table.setLocationAndSize(x+width, y, 500, 400);
for (i = 0; i < nRois; i++) {
	selectWindow(image);
	roiManager("select",i);
	roiManager("Rename", "cell "+i+1);
	run("Plot Z-axis Profile");
	plot = getTitle();
	//run BAR script to find and list the peaks
	run("Find Peaks", "min._peak_amplitude="+tolerance+" min._peak_distance=0 min._value=[] max._value=[] list");
	if(endFrame!=-1) Plot.setLimits(0,endFrame,0.5,maxRatio);
	else Plot.setLimits(0,framesOriginal,0.5,maxRatio);
	Plot.setXYLabels("time (frames)", "Ratio");
	rename("cell "+i+1);

	close(plot);

	selectWindow("Plot Values");
	//Get peak info
	ratioData = Table.getColumn("Y0");
	maxPos = Table.getColumn("X1");
	minPos = Table.getColumn("X2");
	Array.sort(maxPos);
	Array.sort(minPos);
	close("Plot Values");

	totalDuration = 0;
	totalHeight = 0;
	totalArea = 0;
	n = 0;
	if(maxPos.length > 0) {
		//Remove the first minimum if it comes earlier than the first maximum
		if(minPos[0] < maxPos[0]) minPos = Array.deleteIndex(minPos, 0);
		if(minPos.length!=0) {
			if(maxPos[maxPos.length-1] > minPos[minPos.length-1]) maxPos = Array.deleteIndex(maxPos, maxPos.length-1);
		}

		//process all peaks
		for(n = 0 ; n < maxPos.length ; n++) {	//n = nr of peaks
			maxAmp[n] = ratioData[maxPos[n]-1];
			if(minPos.length != 0) minAmp[n] = ratioData[minPos[n]-1];
			if(minPos.length != 0) {

				//print(minAmp[n]);
				Array.fill(peakArea,0);
				t = maxPos[n]-1;
				while(ratioData[t] >= (maxAmp[n] - minAmp[n])/3 + minAmp[n]) {	//Keep counting until the curve drops to 1/3
					//print(t, ratioData[t]);
					peakArea[n] += ratioData[t] - 1;
					print(n, t, peakArea[n], ratioData[t] - 1);
					t++;
					totalDuration++;
				}
			}
			totalHeight += maxAmp[n];
			totalArea += peakArea[n];

			//print(maxPos[n]-1, maxAmp[n], minPos[n]-1, minAmp[n]);
			
			currentRow = nResults;
			setResult("cell nr", currentRow, i+1);
			setResult("peak frame", currentRow, maxPos[n]-1);
			if(minPos.length != 0) setResult("peak duration [frames]", currentRow, t-maxPos[n]+1);
			else setResult("peak duration [frames]", currentRow, NaN);
			setResult("peak height (=max ratio)", currentRow, maxAmp[n]);
			if(minPos.length != 0) setResult("peak strength (~area)", currentRow, peakArea[n]);
			else setResult("peak strength (~area)", currentRow, NaN);
		}
	}
	Table.set("Cell", i, i+1, summaryTable);
	Table.set("Peak count", i, maxPos.length, summaryTable);
	Table.set("Total duration", i, totalDuration, summaryTable);
	Table.set("Average height", i, totalHeight/n, summaryTable);
	Table.set("Total strength", i, totalArea, summaryTable);
	Table.update;
}
if(nRois>1) run("Images to Stack", "name=Profiles title=cell use");
else if(nRois==0)showMessage("No ROIs to analyze.");

restoreSettings;