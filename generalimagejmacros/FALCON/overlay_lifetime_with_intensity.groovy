import ij.IJ
import ij.ImagePlus
import ij.ImageStack
import ij.plugin.ChannelSplitter
import ij.plugin.ImageCalculator
import ij.process.LUT
import ij.plugin.RGBStackMerge
//import ij.gui.GenericDialog

boolean averageIntensity = true;
double[] displayRangeInt = [0,500]
double[] displayRangeLifetime = [1500,3500]

//IJ.run("Close All", "");

//Lifetime image
lifetimeImage = IJ.openImage("C:/Users/b.vd.broek/surfdrive/DATA/Olga/OverlayTest/lifetime.tif")
title = lifetimeImage.getTitle()

IJ.run(lifetimeImage, "physics_black", "")
lifetimeImage.setDisplayRange(displayRangeLifetime[0],displayRangeLifetime[1]);
IJ.run(lifetimeImage, "RGB Color", "")
//lifetimeImage.show()
ImagePlus[] channels = ChannelSplitter.split(lifetimeImage);

//Intensity image
intensityImageTemp = IJ.openImage("C:/Users/b.vd.broek/surfdrive/DATA/Olga/OverlayTest/intensity.tif")
if(averageIntensity==true) {
	IJ.run(intensityImageTemp, "Z Project...", "projection=[Average Intensity]")
	intensityImage = IJ.getImage()
}
else intensityImage = intensityImageTemp;
intensityImage.setDisplayRange(displayRangeInt[0],displayRangeInt[1]);
IJ.run(intensityImage, "Apply LUT", "stack");
//intensityImage.show()

//Multiply each channel with intensityImage
ic = new ImageCalculator()
red = ic.run("multiply create stack 32-bit", channels[0], intensityImage)
green = ic.run("multiply create stack 32-bit", channels[1], intensityImage)
blue = ic.run("multiply create stack 32-bit", channels[2], intensityImage)

ImagePlus[] RGBImage = [red,green,blue]

merge = RGBStackMerge.mergeChannels(RGBImage, false)
IJ.run(merge, "RGB Color", "slices");
merge.setTitle(title+" overlay");
merge.show()
IJ.doCommand("Start Animation [\\]");

red.close()
green.close()
blue.close()
IJ.run(intensityImage, "Close", "")
