//kjMakeTensorflowData3..... KJ, Dec 2019
//ad hoc macro to make circle/rectangle etc data for tensorflow deep learning
//it writes a descriptor file with # of trainings, # of tests, and imagesize.
//then it runs the business end twice, once for train and test each.
//VERSIE D. like 2nd example: variable size, now in 50x50 and with non-filled shapes, also noise added to bkgnd

run("Close All");
aantaltrain=250000;
aantaltest=1000;
grootte=50;
margin=12; // for circles
f=File.open("C:/dataff/kjDescriptor.txt"); //I bet Bram has nasty comments on this again
print(f,aantaltrain);
print(f,aantaltest);
print(f,grootte);
File.close(f);
run("Line Width...", "line=2");//<<<<<<<<<<<<<<<<<<<<<
		
run("Close All");
kjFillStackWithObjects(aantaltrain, grootte, margin, "train");
run("Close All");
kjFillStackWithObjects(aantaltest, grootte, margin, "test");


function kjFillStackWithObjects(aantal, grootte, margin, fname){
	f=File.open("C:/dataff/y_"+fname+".txt");
	newImage("Data", "random", grootte,grootte,aantal);
	run("Multiply...", "value=0.10 stack");
	
	for (i=1;i<=aantal;i++){
	setSlice(i);		
		makeRandom=round(random*5); //to make random order of objects. Not really necessary.
		if (makeRandom==0){	//circle
			x=round(random*(grootte - 2*margin));
			y=round(random*(grootte - 2*margin));
			radius=margin+round(random*margin);
			print(f,1); //this outputs the ground truth to a file
			makeOval(x, y, radius, radius);
			setForegroundColor(255, 0, 0);
			run("Fill", "slice");
		}
		if (makeRandom==1) {
			x=round(random*(grootte - 2*margin));
			y=round(random*(grootte - 2*margin));
			z=margin+round(random*margin);
			print(f,2);
			makeRectangle(x, y, z,z);
			setForegroundColor(255, 0, 0);
			run("Fill", "slice");
		}
		if (makeRandom==2){
			x1=round(random*grootte/2);
			y1=round(random*grootte/2);
			x2=x1+margin +round(random*margin);
			y2=y1+2;
			x3=x1+2;
			y3=y1+margin +round(random*margin);
			print(f,3);
			makePolygon(x1, y1, x2, y2, x3, y3);
			setForegroundColor(255, 0, 0);
			run("Fill", "slice");
		}
		if (makeRandom==3){	//circle
			x=round(random*(grootte - 2*margin));
			y=round(random*(grootte - 2*margin));
			radius=margin+round(random*margin);
			print(f,4); //this outputs the ground truth to a file
			makeOval(x, y, radius, radius);
			setForegroundColor(255, 0, 0);
			run("Draw", "slice");
		}
		if (makeRandom==4) {
			x=round(random*(grootte - 2*margin));
			y=round(random*(grootte - 2*margin));
			z=margin+round(random*margin);
			print(f,5);
			makeRectangle(x, y, z,z);
			setForegroundColor(255, 0, 0);
			run("Draw", "slice");
		}
		if (makeRandom==5){
			x1=round(random*grootte/2);
			y1=round(random*grootte/2);
			x2=x1+margin +round(random*margin);
			y2=y1+2;
			x3=x1+2;
			y3=y1+margin +round(random*margin);
			print(f,6);
			makePolygon(x1, y1, x2, y2, x3, y3);
			setForegroundColor(255, 0, 0);
			run("Draw", "slice");
		}
	}
		//run("Delete Slice");	
		saveAs("Raw Data", "C:/dataff/x_"+fname);
	
	File.close(f);
}
