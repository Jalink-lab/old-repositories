#@ Integer (label = "Median filter before thresholding", value=0, style="spinner", min=0, max=20) median_radius
#@ String(label = "Local threshold method", choices={"Bernsen", "Contrast", "Mean", "Median", "MidGrey", "Niblack", "Otsu", "Phansalkar", "Sauvola"}, style="listbox") method
#@ Integer (label = "Radius (pixels)", style = "spinner", value=50, min=-1000, max=1000) radius
#@ Float (label = "Parameter 1 minimum", style = "spinner", value=0, min=-10000, max=10000) par1_min
#@ Float (label = "Parameter 1 maximum", style = "spinner", value=1, min=-10000, max=10000) par1_max
#@ Float (label = "Nr. of steps", style = "spinner", value=10, min=1, max=100) steps
#@ Boolean (label = "Sweep parameter 2 as well? (Else the minimum value is used)") sweep_par2
#@ Float (label = "Parameter 2 minimum", style = "spinner", value=0, min=-10000, max=10000) par2_min
#@ Float (label = "Parameter 2 maximum", style = "spinner", value=1, min=-10000, max=10000) par2_max
#@ Boolean (label = "Enforce gray LUT?") gray


setBatchMode(true);
image = getTitle;
original = image;
k=0;

if(median_radius>0) {
	run("Duplicate...", "title="+image+"_medianfiltered");
	run("Median...", "radius="+median_radius);
	image = getTitle;
}

bits = bitDepth;
if(bits!=8) {
	run("Duplicate...", "title="+image+"_8bit");
	image = getTitle;
	run("8-bit");
}
if(gray==true) run("Grays");

print("\\Clear");
if(sweep_par2==true) {
	for(i=0;i<=steps;i++) {
		par2 = par2_min + i*(par2_max-par2_min)/steps;

		for(k=0;k<=steps;k++) {
			par1 = par1_min + k*(par1_max-par1_min)/steps;
			//print(par1);

			selectWindow(image);
			run("Duplicate...", "title=[threshold "+par1+" , "+par2+"]");
			showProgress(i/(steps+1) + k/(steps+1)*(steps+1));
			run("Auto Local Threshold", "method="+method+" radius="+radius+" parameter_1="+par1+" parameter_2="+par2+" white stack");
		}
	}
	run("Images to Stack", "name=Thresholded_radius_"+radius+" title=threshold use");
	run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices="+steps+1+" frames="+steps+1+" display=Grayscale");
}
else {
	par2=par2_min;
	for(k=0;k<=steps;k++) {
		par1 = par1_min + k*(par1_max-par1_min)/steps;
		//print(par1);

		selectWindow(image);
		run("Duplicate...", "title=[threshold "+par1+" , "+par2+"]");
		showProgress(k/(steps+1));
		run("Auto Local Threshold", "method="+method+" radius="+radius+" parameter_1="+par1+" parameter_2="+par2+" white stack");
	}
	run("Images to Stack", "name="+method+"_radius_"+radius+" title=threshold use");
	run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices="+steps+1+" frames=1 display=Grayscale");
}

run("Red");
for(k=0;k<=steps;k++) {
	Stack.setSlice(k+1);
	run("Add Image...", "image="+image+" x=0 y=0 opacity=50");
}
rename(original+"_thresholded");

if(bits!=8) close(image+"_8bit");

Stack.setSlice(1);
Stack.setFrame(1);
setBatchMode("show");
