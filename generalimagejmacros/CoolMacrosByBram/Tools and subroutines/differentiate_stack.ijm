stack = getTitle();
getDimensions(width, height, channels, slices, frames);

setBatchMode(true);

run("Duplicate...", "title=duplicated_stack duplicate");
run("Reverse");
Stack.setSlice(slices);
run("Add Slice");
run("Reverse");
Stack.setSlice(slices+1);
run("Delete Slice");
imageCalculator("Subtract create 32-bit stack","duplicated_stack", stack);
rename(stack+"_differentiated");
setBatchMode("show");
close("duplicated_stack");