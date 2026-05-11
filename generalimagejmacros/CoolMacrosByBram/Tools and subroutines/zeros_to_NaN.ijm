// Changes all pixels with value 0 to NaN.

run("32-bit");
getDimensions(width, height, channels, slices, frames);
nr=0;
for(c=1;c<=channels;c++) {
	Stack.setChannel(c);
	showProgress(c/channels);
	for(z=1;z<=slices;z++) {
		Stack.setSlice(z);
		for(f=1;f<=frames;f++) {
			Stack.setFrame(f);
			changeValues(0, 0, NaN);
		}
	}
}
updateDisplay();
print(nr+" zeros replaced by NaNs");
