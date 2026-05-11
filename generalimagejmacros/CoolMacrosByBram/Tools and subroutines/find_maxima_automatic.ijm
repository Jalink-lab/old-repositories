var	elements = 200;
var multiplier = 1;
var offset = 0;
var plateau_length = 4;
var points_to_fit_exp = 5;
var apply_LoG = false;
var sigma_Gauss = 1;
var sensitivity = 25;

var nr_maxima = newArray(elements);
var diff_maxima = newArray(elements);
	
print("\\Clear");
run("Clear Results");

setBatchMode(true);

image = getTitle;

if(selectionType!=0) {
setTool("rectangle");
waitForUser("Draw selection");
}
if(apply_LoG==true) {
	//sigma_Gauss = 0.5;
	run("Duplicate...", "title=selection");
	run("32-bit");
	run("Gaussian Blur...", "sigma="+sigma_Gauss);					//Gaussian
	run("Convolve...", "text1=[0 1 0\n1 -4 1\n0 1 0\n] normalize");	//Laplacian
	run("Invert", "stack");
	rename("selection");
}
else run("Duplicate...", "title=selection");


nr_maxima = estimate_threshold_noise_level("selection");

nr_maxima_expfit = Array.slice(nr_maxima, offset, points_to_fit_exp+offset);
x_points_expfit = Array.getSequence(points_to_fit_exp);
x_points_expfit = PointMultiplyArray(x_points_expfit, multiplier);

Fit.doFit("Exponential", x_points_expfit, nr_maxima_expfit);
Fit.plot;
Plot.setLogScaleY(true);
setBatchMode("show");
print("Initial exponential decrease: "+Fit.p(1));
max_plateau_fall = -sensitivity*Fit.p(1);	//Very arbitrary
//n=0;		//plateau length counter 
i=offset;	//counter, starting at offset
threshold_noise_level = -1;
while(i<elements-plateau_length/2) {
	if(i>offset+plateau_length) {	//to prevent negative numbers
		if(nr_maxima[i]>=(nr_maxima[i-plateau_length]-max_plateau_fall) && nr_maxima[i]!=0) {	//check if nr_maxima is the same for plateau_length, and not zero
			print("plateau reached at "+i*multiplier+ " ("+i+"th step)");
			threshold_noise_level = i*multiplier-plateau_length;
			threshold_maxima = nr_maxima[i];
			print("threshold noise level: "+threshold_noise_level+", "+threshold_maxima+" maxima in selection.");
			i=elements;	//break from while loop
		}
	}
	i++;
	if(i>=elements && threshold_noise_level==-1) {
		print("No plateau of length "+plateau_length+" found. Decreasing size...");
		plateau_length -= 1;
		i=offset;
	}
}

x_points = Array.getSequence(elements);
x_points = PointMultiplyArray(x_points, multiplier);
x_points_threshold = Array.slice(x_points, threshold_noise_level/multiplier - plateau_length + 1, threshold_noise_level/multiplier + 1);
x_points = Array.slice(x_points, offset, elements);		//remove points < offset
nr_maxima = Array.slice(nr_maxima, offset, elements);	//remove points < offset

y_points_threshold = newArray(plateau_length);
Array.fill(y_points_threshold, threshold_maxima);

Plot.create("Maxima vs tolerance", "tolerance", "maxima count");
Plot.setLineWidth(2);
Plot.setColor("blue");
Plot.add("line", x_points, nr_maxima);
Plot.setLineWidth(4);
Plot.setColor("red");
Plot.add("line",x_points_threshold,y_points_threshold);
Plot.setLineWidth(1);
Plot.setLimits(1, NaN, 1, NaN);
Plot.setLogScaleY(true);
Plot.show;
setBatchMode("show");

selectWindow(image);
run("Select None");
run("Clear Results");
run("Find Maxima...", "noise="+threshold_noise_level+" output=List");
run("Find Maxima...", "noise="+threshold_noise_level+" output=[List]");
run("Find Maxima...", "noise="+threshold_noise_level+" output=[Point Selection]");

/*
 * NEXT:
 * - Analyze everything on DoG image
 * 
 * - set autothreshold (Otsu, MaxEntropy, Triangle?) or determine background (e.g. median) and set threshold above.
 * - find maxima with threshold_noise_level, above threshold, output Maxima within tolerance
 * - Analyze particles, throw away large ones (corresponding to bright blobs or nothing)
 * 
 * - Alternatively, draw a small box around each selection, and check for StdDev, intensity
 * - Also, compare DoG maxima with original; keep only the ones close to each other
 */


function estimate_threshold_noise_level(image1) {
	selectWindow(image1);
	//setBatchMode(true);
	for(i=1+offset;i<=elements;i++) {
	showProgress((i-offset)/(elements-offset));
		run("Find Maxima...", "noise="+i*multiplier+" output=[Count] above");
		nr_maxima[i-1]=getResult("Count");
	}
	//setBatchMode(false);
	//Array.sort(nr_maxima);
	return nr_maxima;
}


function PointMultiplyArray(array, scalar) {
	multiplied_array=newArray(lengthOf(array));
	for (a=0; a<lengthOf(array); a++) {
		multiplied_array[a]=array[a]*scalar;
	}
	return multiplied_array;
}