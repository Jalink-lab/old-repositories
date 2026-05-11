setOption("ExpandableArrays", true);

print("\\Clear");
//path = "C:\\Users\\Bram\\surfdrive\\FALCON Analysis\\07-19-2018\\07-09-2018_baseline.ome-xml.txt";
path = getArgument();

length_of_string = 12;

Pos_X = newArray;
Pos_Y = newArray;

data = File.openAsString(path);
index_x = newArray;
index_y = newArray;

i=0;
last_index_x = lastIndexOf(data, "PositionX=");
do{
	//Find indices
	if(i==0) {
		index_x[i] = indexOf(data, "PositionX=", 0);
		index_y[i] = indexOf(data, "PositionY=", 0);
	}
	else {
		index_x[i] = indexOf(data, "PositionX=", index_x[i-1]+1);	//Start looking one character further than the previous iteration 
		index_y[i] = indexOf(data, "PositionY=", index_y[i-1]+1);
	}
	Pos_X[i] = parseFloat(substring(data, index_x[i]+11, index_x[i]+11+length_of_string));
	Pos_Y[i] = -parseFloat(substring(data, index_y[i]+11, index_y[i]+11+length_of_string));	//minus sign here!
	i++;
} while(index_x[i-1]!=last_index_x);

//Remove double occurences
for(i=1;i<Pos_X.length;i++) {
		if(Pos_X[i]==Pos_X[i-1] && Pos_Y[i]==Pos_Y[i-1]) {
			Pos_X = deleteFromArray(Pos_X, i);
			Pos_Y = deleteFromArray(Pos_Y, i);
		}
	}

//Return the X,Y positionsas a string
coordinates_string = "";
for (i=0;i<Pos_X.length;i++) {
	coordinates_string += toString(d2s(Pos_X[i],10),10) + "," + toString(d2s(Pos_Y[i],10),10) + "|";	//use 10 decimals
}
return coordinates_string;



function deleteFromArray(array, position) {
	if (position<lengthOf(array)) {
		Array.rotate(array, -position);
		array = Array.slice(array,1,array.length);
		Array.rotate(array, position);
	}
	return array;
}