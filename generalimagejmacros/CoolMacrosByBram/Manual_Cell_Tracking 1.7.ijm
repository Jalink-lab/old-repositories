/* Macro to manually track cells and save the individual movies.
 * Cells are tracked by left clicking in the maximum intensity projection window.
 * It is also possible to hold the left mouse button in this window and keep the mouse
 * at the center of the cell while it is tracked. Optionally a time delay can be set.
 *
 * Tracking of a cell ends by pressing 'shift' or at the end of the movie.
 * ROIs around the first frame are displayed and saved.
 * 
 * Bram van den Broek, Netherlands Cancer Institute, 2013-02-15
 * 
 * Version 1.1:
 * -Possibility to set a start frame>1 for tracking
 * 
 * Version 1.3, December 2014:
 * - Possibility to reverse the movie for tracking (easier to spot interesting cells)
 * - Possibility to delete the last frame, as can sometimes be black
 * - Possibility to track on an RGB of all channels in stead of one channel
 * 
 * Version 1.4, Februari 2015:
 * - preservation of pixel and time units
 * - Harder
 * - Better
 * - Faster
 * - Stronger
 * 
 * Version 1.5, Februari 2015
 * - automatic subtraction of 2^15 (32768) if appropriate (Deltavision data sometimes has this).
 * 
 * Version 1.6, January 2017
 * - Display the square selection also in tracking window
 * 
 * Version 1.7, August 2018
 * - Save the tracked trajectory
 */

saveSettings();

run("Input/Output...", "jpeg=85 gif=-1 file=.txt use_file save_column");

var reverse_movie = false;
var delete_last_frame = false;
var track_on_RGB = true;

var tracking_channel = 2;
var size = 80;
var use_delay = true;
var delay = 200;
var zoom = 2;
var x0;
var y0;
var x_previous;
var y_previous;
var trajectory_x = newArray(9999);	//up to 9999 frames
var trajectory_y = newArray(9999);	//up to 9999 frames
var start_frame=1;

if (nImages>0) run("Close All");
path = File.openDialog("Select movie for tracking cells");
//run("Bio-Formats Windowless Importer", "open=["+path+"]");
open(path);

setLineWidth(1);
run("Line Width...", "line=1");
print("\\Clear");
roiManager("reset");
call("ij.gui.ImageWindow.setNextLocation", 0, 0);	//location of next window

dir = getDirectory("image");
//print(dir);
original_name = getTitle();
file_name_without_extension = File.nameWithoutExtension;
run("Select None");
Stack.setFrame(1);
Stack.setSlice(1);
getDimensions(width, height, channels, slices, frames);
//print(channels, slices, frames);
if(frames==1) exit("File is not a movie (frames=1)");
fi = Stack.getFrameInterval();
getPixelSize(unit, pw, ph, pd);
Stack.getUnits(X_unit, Y_unit, Z_unit, time_unit, Value);
getLocationAndSize(x_window, y_window, width_window, height_window);
if(channels>1) Stack.setDisplayMode("composite");
setLocation(0, 0);


//Remove senseless "calibration" of Deltavision
info = getImageInfo();
index = indexOf(info, "Calibration Function");
if (index!=-1) {
	run("Calibrate...", "function=None unit=[Gray Value]");
	run("Subtract...", "value=32768 stack");
	for(c=1;c<=channels;c++) {
		Stack.setChannel(c);
		resetMinAndMax();
		}
	Stack.setChannel(1);
}


if (File.exists(dir+file_name_without_extension+"_ROIs.zip")) {	//load ROIs of previously tracked cells in this file
	roiManager("Open", dir+file_name_without_extension+"_ROIs.zip");
	roiManager("Show None");
	cell=roiManager("count")+1;
	showMessage(cell-1+" cells in this file have already been tracked.\nTracking will continue at cell nr. "+cell+"."); 
}
else cell=1;



//---------OPEN DIALOG
Dialog.createNonBlocking("Options");
	Dialog.addMessage("Manual Tracking\n\nHold left mouse button to track\nPress 'shift' to end the track.")
	if(channels>1) Dialog.addCheckbox("Track viewing all channels", track_on_RGB);
	if(channels>1) Dialog.addSlider("or a single channel", 1, channels, tracking_channel);
	Dialog.addCheckbox("Reverse movie for tracking? (doesn't work for z-stacks)", reverse_movie);
	Dialog.addNumber("size of square (pixels)", size);
	Dialog.addCheckbox("Use a time delay for holding down left button (anti-RSI)?", use_delay);
	Dialog.addSlider("delay (ms)", 100, 2000, delay);
Dialog.show;
	if(channels>1) track_on_RGB=Dialog.getCheckbox();
	else track_on_RGB=false;
	if(channels>1) tracking_channel=Dialog.getNumber();
	else tracking_channel=1;
	reverse_movie=Dialog.getCheckbox();
	size=Dialog.getNumber();
	use_delay=Dialog.getCheckbox();
	delay=Dialog.getNumber();

for(i=1;i<=channels;i++) {
	Stack.setChannel(i);
	run("Enhance Contrast", "saturated=0.2");
}

//Automatic Lennert mode: delete last frame when it is empty
Stack.setFrame(frames);
List.setMeasurements();
signal = List.getValue("IntDen");
if(signal==0) {
	run("Delete Slice", "delete=frame");
	print("Lennert mode activated: deleting frame "+frames);
}
Stack.setFrame(1);
getDimensions(width, height, channels, slices, frames);


if(reverse_movie==true && channels>1 && slices==1) {
	run("Split Channels");
	string = "";
	for(i=1;i<=channels;i++) {
		selectWindow("C"+i+"-"+original_name);
		run("Reverse");
		//generate the string for merging of all channels
		string = string + "c"+i+"=[C"+i+"-"+original_name+"] ";
	}
	run("Merge Channels...", string+" create");
}
else if(reverse_movie==true && slices==1) run("Reverse");
Stack.setChannel(tracking_channel);
call("ij.gui.ImageWindow.setNextLocation", 0, 0);
if (slices>1) {
	run("Z Project...", "projection=[Max Intensity] all");
	rename("projection");
	setBatchMode("hide");
}
call("ij.gui.ImageWindow.setNextLocation", width_window, 0);
if(track_on_RGB==false) run("Duplicate...", "title=projection duplicate channels="+tracking_channel);
else {
	run("Duplicate...", "duplicate");
	call("ij.gui.ImageWindow.setNextLocation", width_window, 0);
	run("RGB Color", "frames ");
}
rename("tracking_window");
setBatchMode("show");
if (channels>1 && track_on_RGB==false) {
	for(i=1;i<=channels;i++) {
	Stack.setChannel(i);
//	run("Grays");
	run("Enhance Contrast", "saturated=0.2");
//	run("Brightness/Contrast...");
//	waitForUser("Set contrast levels for tracking channel(s)");
	}
}
if(channels>1) Stack.setChannel(tracking_channel);
roiManager("Associate", "true");	//associate 'Show All' with slices/frames
roiManager("Show all with labels");

do {
	run("Remove Overlay");
	track_cell(cell);
	selectWindow("cell_"+cell);
	run("Properties...", "unit="+unit+" pixel_width="+pw+" pixel_height="+ph+" voxel_depth="+pd+" frame=["+fi+" "+time_unit+"]");
	waitForUser("Tracking of cell "+cell+" completed. Please inspect result.");
	keep=getBoolean("Keep cell "+cell+"?");
	if(keep==true) {
		selectWindow("cell_"+cell);
		saveAs("Tiff", dir+file_name_without_extension+"_"+"cell_"+cell);
		saveAs("Results", dir+file_name_without_extension+"_"+"cell_"+cell+"_trajectory.xls");
		selectWindow("tracking_window");
		Stack.setFrame(start_frame);
		makeOval(x0-size/2,y0-size/2,size,size); //create ROI for this cell
		roiManager("Add");
		roiManager("Select", cell-1);	//first ROI has index 0
		roiManager("Rename", "cell_"+cell);
		cell++;
	}
	else {
		selectWindow("cell_"+cell);
		run("Close");
		selectWindow("tracking_window");
		Stack.setFrame(1);
	}
	roiManager("Show all with labels");
	next=getBoolean("Next cell?");
} while(next==true)
//save ROIs to file
roiManager("Select All");
if (roiManager("count")>0) roiManager("Save", dir+file_name_without_extension+"_ROIs.zip");

restoreSettings();





function track_cell(cell) {
	//flags
	shift=1;
	ctrl=2; 
	rightButton=4;
	alt=8;
	leftButton=16;
	insideROI = 32; // requires 1.42i or later

	x2=-1; y2=-1; z2=-1; flags2=-1;

	Array.fill(trajectory_x, 0);	//clear trajectory
	Array.fill(trajectory_y, 0);
	setColor(255, 0, 255);

	roiManager("Show All with labels");
	waitForUser("Select start frame");
	roiManager("Show None");
	Stack.getPosition(_channel_, _slice_, start_frame)

	j=start_frame;	//reset frame nr to start_frame
	k=0;			//rectangular overlay counter
	n=0;			//trajectory counter
	step_length = 0;
	trajectory_length = 0;
	end_loop=false;
	run("Clear Results");
	
	selectWindow("tracking_window");
	Stack.setFrame(j);
	setOption("DisablePopupMenu", true);
	setBatchMode(true);
	
	while(!isKeyDown("shift") && end_loop!=true){
		getCursorLoc(x, y, z, flags);

		if (flags&leftButton!=0) {
			trajectory_x[j-1]=x;
			trajectory_y[j-1]=y;
			selectWindow("tracking_window");
			if(j==start_frame) {
				x_previous=x;
				y_previous=y;
			}
			setLineWidth(1);
			setColor(151, 0, 151);
			Overlay.drawLine(x_previous, y_previous, x, y);
			Overlay.show;
			setLineWidth(2);
			setColor(255, 0, 255);
			Overlay.drawEllipse(x-1, y-1, 2, 2);
			Overlay.show;
			setLineWidth(1);
			setColor(0, 255, 255);
			if(k>0) Overlay.removeSelection(k);	//remove previous rectangle
			k+=2;
			Overlay.drawRect(x-size/2,y-size/2,size,size);
			Overlay.show;

			//calculate trajectory
			step_length = pw*sqrt( (pow((x-x_previous),2)+pow((y-y_previous),2)) );
			trajectory_length += step_length;
			setResult("frame", n, j);
			setResult("X", n, x);
			setResult("Y", n, y);
			setResult("length", n, step_length);
			setResult("total_length", n, trajectory_length);
			updateResults;
			n++;
			
			x_previous=x;
			y_previous=y;
			//roiManager("Show None");
//			Stack.setFrame(j);
//			makeRectangle(x-size/2,y-size/2,size,size);
			selectWindow(original_name);
//			Stack.setFrame(j);
			makeRectangle(x-size/2,y-size/2,size,size);
			call("ij.gui.ImageWindow.setNextLocation", width_window*2, 0);
			if (slices>1 || channels>1) run("Duplicate...", "title=cell_"+cell+"_frame_"+j+" duplicate frames="+j);
			else run("Duplicate...", "title=cell_"+cell+"_frame_"+j+" frames="+j);
			if(getHeight!=size||getWidth!=size) run("Canvas Size...", "width="+size+" height="+size+" position=Center zero");	//preventing crash at image edges
			if(j==start_frame) {x0=x;	y0=y;}	//get starting position for ROI
			call("ij.gui.ImageWindow.setNextLocation", width_window*2, 0);
			if(j>start_frame) {
				run("Concatenate...", "stack1=cell_"+cell+"_frame_"+start_frame+" stack2=cell_"+cell+"_frame_"+j+" title=cell_"+cell+"_frame_"+start_frame);	//concatenate cropped frames
//				run("Stack to Hyperstack...", "order=xyczt(default) channels=2 slices=3 frames=6 display=Color");
				//Stack.setChannel(tracking_channel);
				//Stack.setSlice(slices*(j-1)+round(slices/2));
			}
			//for(k=0;k<zoom;k++) run("In [+]");
			j++;
			selectWindow(original_name);
			Stack.setFrame(j);
			selectWindow("tracking_window");
			Stack.setFrame(j);
			if (use_delay==true) wait(delay);
		}
		//print(j);
		//print(frames);
		if(j>frames) end_loop=true;
		
		selectWindow("tracking_window");
		wait(25);
		x2=x; y2=y; z2=z; flags2=flags;
	}
	Overlay.removeSelection(k);	//remove the last selection
	setOption("DisablePopupMenu", false);

	selectWindow("cell_"+cell+"_frame_"+start_frame);

	setBatchMode(false);
	
	if(j>start_frame) {	//skip this part if 'shift' is pressed before a frame is tracked. Still gives problems though.
		selectWindow("cell_"+cell+"_frame_"+start_frame);
		rename("cell_"+cell);
		if(j>start_frame+1) {	//only do this when at least one frame is tracked (1 is added to j anyway, so 2 is needed here)
			run("Stack to Hyperstack...", "order=xyczt(default) channels="+channels+" slices="+slices+" frames="+j-start_frame+" display=Color");
			selectWindow("cell_"+cell);
			for(k=0;k<zoom;k++) {
				selectWindow("cell_"+cell);
				run("In [+]");
			}
			for(i=1;i<=channels;i++) {
				Stack.setChannel(i);
				//run("Grays");
				run("Enhance Contrast", "saturated=0.2");
			}
			Stack.setChannel(tracking_channel);
			Stack.setFrame(1);
		}
	}
	getLocationAndSize(x_crop, y_crop, width_crop, height_crop);
	if(reverse_movie==true && channels>1 && slices==1) {
		selectWindow("cell_"+cell);
		run("Split Channels");
		string = "";
		for(i=1;i<=channels;i++) {
			selectWindow("C"+i+"-cell_"+cell);
			run("Reverse");
			//generate the string for merging of all channels
			string = string + "c"+i+"=[C"+i+"-cell_"+cell+"] ";
		}
		run("Merge Channels...", string+" create");
		rename("cell_"+cell);
	}
	else if(reverse_movie==true && slices==1) run("Reverse");
	setBatchMode("show");
	setLocation(width_crop*(cell-1)%screenWidth, height_window); //place the window below the original and next to the last tracked cell
	if(channels>1) Stack.setDisplayMode("composite");
}
