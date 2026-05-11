Stack.setChannel(3);
Stack.getDimensions(width, height, channels, slices, frames);
for (i = 0; i < frames; i++) {
	Stack.setFrame(i);
}