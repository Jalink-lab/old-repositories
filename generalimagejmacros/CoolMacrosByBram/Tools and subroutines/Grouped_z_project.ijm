#@Integer (label="Group size", value=5) groupSize
original = getTitle;
getDimensions(width, height, channels, slices, frames);
k=1;
string = "";
setBatchMode(true);
for (i = 0; i < slices; i+=groupSize) {
	showProgress(i,groupSize);
	selectWindow(original);
	run("Z Project...", "start="+i+1+" stop="+i+groupSize+" projection=[Max Intensity] all");
	rename("projection_"+k);
	string += "image"+k+"=projection_"+k+" ";
	k++;
	if(k*groupSize > slices) i=slices;	//End the loop
}
print(string);
run("Concatenate...", "open "+string);
run("Stack to Hyperstack...", "order=xyctz channels="+channels+" slices="+k-1+" frames="+frames+" display=Color");
rename(substring(original,0,lastIndexOf(original, ".")) + "_grouped");
setBatchMode("exit and display");
