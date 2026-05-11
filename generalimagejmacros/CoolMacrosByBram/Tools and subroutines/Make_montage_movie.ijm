//Make montage of a multichannel movie. Does not work for z-stacks (yet).

original = getTitle();
getDimensions(width, height, channels, slices, frames);


newImage(original+"_montage","RGB black", width*3,height,frames);

setBatchMode(true);

for(c=1;c<=channels;c++) {
	selectWindow(original);
	Stack.setChannel(c);
	for(f=1;f<=frames;f++) {
		selectWindow(original);
		Stack.setFrame(f);
		makeRectangle(0, 0, width, height);
		run("Copy");
		selectWindow(original+"_montage");
		setSlice(f);
		makeRectangle((c-1)*width, 0, width, height);
		run("Paste");
	}
}
