#@ File (label = "Input file", style = "file") input

open(input);
folder = getDirectory("image");
name = File.nameWithoutExtension;

original = getTitle();
getDimensions(width, height, channels, slices, frames);
makeRectangle(0, 0, width/2, height);
run("Duplicate...", "title=left duplicate");
selectWindow(original);
makeRectangle(width/2, 0, width/2, height);
run("Duplicate...", "title=right duplicate");
run("Merge Channels...", "c1=left c2=right create");

saveAs("Tiff", folder + File.separator + name + "_ratio");