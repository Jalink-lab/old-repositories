//Adds the value to the array at the specified position, expanding if necessary
//Returns the modified array
function addToArray(value, array, position) {
	if (position<lengthOf(array)) {
		array[position]=value;
	} else {
		temparray=newArray(position+1);
		for (i=0; i<lengthOf(array); i++) {
			temparray[i]=array[i];
		}
		temparray[position]=value;
		array=temparray;
	}
	return array;
}

//Delete the specified entry, shifting the other positions 
function deleteFromArray(value, array, position) {
	if (position<lengthOf(array)) {
		Array.rotate(array, -position);
		array = Array.slice(array,1,array.length);
		Array.rotate(array, position);
	}
}


//Appends the value to the array
//Returns the modified array
function appendToArray(value, array) {
	temparray=newArray(lengthOf(array)+1);
	for (i=0; i<lengthOf(array); i++) {
		temparray[i]=array[i];
	}
	temparray[lengthOf(temparray)-1]=value;
	array=temparray;
	return array;
}

//Prints the array in a human-readable form
function printArray(array) {
	string="";
	for (i=0; i<lengthOf(array); i++) {
		if (i==0) {
			string=string+array[i];
		} else {
			string=string+", "+array[i];
		}
	}
	print(string);
}

//Returns the minimum of the array
function minOfArray(array) {
	max=0;
	for (a=0; a<lengthOf(array); a++) {
		max=maxOf(array[a], max);
	}
	min=max;
	for (a=0; a<lengthOf(array); a++) {
		min=minOf(array[a], min);
	}
	return min;
}

//Returns the maximum of the array
function maxOfArray(array) {
	min=0;
	for (a=0; a<lengthOf(array); a++) {
		min=minOf(array[a], min);
	}
	max=min;
	for (a=0; a<lengthOf(array); a++) {
		max=maxOf(array[a], max);
	}
	return max;
}

//Returns the number of times the value occurs within the array
function occurencesInArray {
	count=0;
	for (a=0; a<lengthOf(array); a++) {
		if (array[a]==value) {
			count++;
		}
	}
	return count;
}

//Returns the indices at which a value occurs within an array
function indexOfArray(array, value) {
	count=0;
	for (a=0; a<lengthOf(array); a++) {
		if (array[a]==value) {
			count++;
		}
	}
	if (count>0) {
		indices=newArray(count);
		count=0;
		for (a=0; a<lengthOf(array); a++) {
			if (array[a]==value) {
				indices[count]=a;
				count++;
			}
		}
		return indices;
	}
}

//Multiplies the elements of two arrays and returns the multiplied array
function multiplyArrays(array1, array2) {
	multiplied_array=newArray(lengthOf(array1));
	for (a=0; a<lengthOf(array1); a++) {
		multiplied_array[a]=array1[a]*array2[a];
	}
	return multiplied_array;
}


//Divides the elements of two arrays and returns the new array
function divideArrays(array1, array2) {
	divArray=newArray(lengthOf(array1));
	for (a=0; a<lengthOf(array1); a++) {
		divArray[a]=array1[a]/array2[a];
	}
	return divArray;
}


//Returns the sum of all elements of an arrays, neglecting NaNs
function sumArray(array) {
	sum=0;
	for (a=0; a<lengthOf(array); a++) {
		if(!isNaN(array[a])) sum=sum+array[a];
	}
	return sum;
}

//Multiplies all elements of an array with a scalar
function multiplyArraywithScalar(array, scalar) {
	multiplied_array=newArray(lengthOf(array));
	for (a=0; a<lengthOf(array); a++) {
		multiplied_array[a]=array[a]*scalar;
	}
	return multiplied_array;
}


//Divides all elements of an array by a scalar
function divideArraybyScalar(array, scalar) {
	divided_array=newArray(lengthOf(array));
	for (a=0; a<lengthOf(array); a++) {
		divided_array[a]=array[a]/scalar;
	}
	return divided_array;
}
