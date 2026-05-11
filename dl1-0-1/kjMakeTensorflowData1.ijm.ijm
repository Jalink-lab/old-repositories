run("Close All");
aantal=1000;
grootte=28;
margin=7; // for circles
fname="x_train";
newImage("Untitled", "8-bit black", grootte, grootte, 1);
rename("data");

for (i=1;i<=aantal;i++){
	makeRandom=round(random*2);
	if (makeRandom==0){
		x=round(random*(grootte - 2*margin));
		y=round(random*(grootte - 2*margin));
		randNumber=2*margin;
		print(1);
		makeOval(x, y, randNumber, randNumber);
		setForegroundColor(255, 0, 0);
		run("Fill", "slice");
		run("Add Slice");
	}
	if (makeRandom==1) {
		x=round(random*(grootte - 2*margin));
		y=round(random*(grootte - 2*margin));
		z=2*margin;
		print(2);
		makeRectangle(x, y, z,z);
		setForegroundColor(255, 0, 0);
		run("Fill", "slice");
		run("Add Slice");
	}

	if (makeRandom==2){
	
		x1=round(random*grootte/2);
		y1=round(random*grootte/2);
		x2=x1+round(random*grootte/2);
		y2=y1+round(random*grootte/5);
		x3=x1+2;
		y3=y1+round(random*grootte/2);
		print(3);
		makePolygon(x1, y1, x2, y2, x3, y3);
		setForegroundColor(255, 0, 0);
		run("Fill", "slice");
		run("Add Slice");
}
			
}
	run("Delete Slice");	
	saveAs("Raw Data", "C:/dataff/"+fname);
	selectWindow(Log);
	saveAs("Text", "C:/dataff/Log.txt");
