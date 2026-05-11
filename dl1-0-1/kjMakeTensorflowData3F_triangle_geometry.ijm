//kjMakeTensorflowData3..... KJ, Dec 2019
//ad hoc macro to make circle/rectangle etc data for tensorflow deep learning
//it writes a descriptor file with # of trainings, # of tests, and imagesize.
//then it runs the business end twice, once for train and test each.
//VERSIE D. like 2nd example: variable size, now in 50x50 and with non-filled shapes, also noise added to bkgnd

setBatchMode(true);

run("Close All");
aantaltrain=160000;
aantaltest=10000;
grootte=50;
margin=12; // for circles
noiseLevel=25;
f=File.open("C:/dataff/kjDescriptor.txt"); //I bet Bram has nasty comments on this again
//Inderdaad Kees. (Rolf ook)
print(f,aantaltrain);
print(f,aantaltest);
print(f,grootte);
File.close(f);
run("Line Width...", "line=2");//<<<<<<<<<<<<<<<<<<<<<

run("Close All");
showStatus("Generating train data...");
kjFillStackWithObjects(aantaltrain, grootte, margin, "train");
//run("Close All");
showStatus("Generating test data...");
kjFillStackWithObjects(aantaltest, grootte, margin, "test");
setBatchMode("exit and display");

function kjFillStackWithObjects(aantal, grootte, margin, fname){
	f=File.open("C:/dataff/y_"+fname+".txt");
	newImage("Data", "8-bit black", grootte,grootte,aantal);
	//run("Multiply...", "value=0.10 stack");
	
	setForegroundColor(127, 127, 127);
	for (i=1;i<=aantal;i++){
	if(i%1000 == 0) showProgress(i, aantal);
	setSlice(i);	
		makeRandom=round(random*5); //to make random order of objects. Not really necessary.
//		makeRandom=5; //only open triangles

		if (makeRandom==0){	//circle
			x=round(random*(grootte - 2*margin));
			y=round(random*(grootte - 2*margin));
			radius=margin+round(random*margin);
			print(f,1); //this outputs the ground truth to a file
			makeOval(x, y, radius, radius);
			run("Fill", "slice");
		}
		else if (makeRandom==1) {
			x=round(random*(grootte - 2*margin));
			y=round(random*(grootte - 2*margin));
			z=margin+round(random*margin);
			print(f,2);
			makeRectangle(x, y, z,z);
			run("Fill", "slice");
		}
		else if (makeRandom==2){
			x1=round(random*(grootte-margin/2)+margin/4);
			y1=round(random*(grootte-margin/2)+margin/4);
			x2=round(random*(grootte-margin/2)+margin/4);
			y2=round(random*(grootte-margin/2)+margin/4);
			x3=round(random*(grootte-margin/2)+margin/4);
			y3=round(random*(grootte-margin/2)+margin/4);
			print(f,3);
			makePolygon(x1, y1, x2, y2, x3, y3);
			run("Fill", "slice");
		}
		else if (makeRandom==3){	//circle
			x=round(random*(grootte - 2*margin));
			y=round(random*(grootte - 2*margin));
			radius=margin+round(random*margin);
			print(f,4); //this outputs the ground truth to a file
			makeOval(x, y, radius, radius);
			run("Draw", "slice");
		}
		else if (makeRandom==4) {
			x=round(random*(grootte - 2*margin));
			y=round(random*(grootte - 2*margin));
			z=margin+round(random*margin);
			print(f,5);
			makeRectangle(x, y, z,z);
			run("Draw", "slice");
		}
		else if (makeRandom==5){
			x1=round(random*(grootte-margin/2)+margin/4);
			y1=round(random*(grootte-margin/2)+margin/4);
			x2=round(random*(grootte-margin/2)+margin/4);
			y2=round(random*(grootte-margin/2)+margin/4);
			x3=round(random*(grootte-margin/2)+margin/4);
			y3=round(random*(grootte-margin/2)+margin/4);
			print(f,6);
			makePolygon(x1, y1, x2, y2, x3, y3);
			run("Draw", "slice");
		}
	}
	//run("Delete Slice");

	run("Select None");
	showStatus("Adding noise...");
	if(noiseLevel!=0) run("Add Specified Noise...", "stack standard="+noiseLevel);
	saveAs("Raw Data", "C:/dataff/x_"+fname);
	run("Set... ", "zoom=600");
	
	File.close(f);
}
