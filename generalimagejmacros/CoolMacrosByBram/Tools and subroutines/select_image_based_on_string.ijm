imageToSelectString = "C=0";	//define the string that should match part of the image title

selectImageByString(imageToSelectString);	//run the function and pass the string to it


function selectImageByString(imageToSelectString) {
	//Get imageList
	images = getList("image.titles");
	//Array.print(images);
	// find first image that contains the title_part
	found=false;
	for(i=0; i< images.length;i++) {
		if(matches(images[i], ".*"+imageToSelectString+".*")) {
			selectWindow(images[i]);
			print("Image \'"+images[i]+"\' selected");
			found=true;
			return;	//This makes sure the first image containing imageToSelectString is selected
		}
	}
	if(found==false) print("No open image with \'"+imageToSelectString+"\' in the title");
}