// Tool to create a histogram from a 1-D Array

import ij.process.ImageProcessor
import ij.process.FloatProcessor

def int[] BBhistogram (float[] array, int nBins = (int)Math.floor(Math.sqrt(array.size())), double histMin = 0, double histMax = 10) {
	fp = new FloatProcessor(array.size(),1,array)
	fp.setHistogramRange(histMin, histMax)	//Doesn't do anything...
	histogram = fp.getHistogram(nBins)
	return histogram
}


//Overloading - convert array to float and use sqrt of array size as nBins default

def int[] BBhistogram (int[] array, int nBins = (int)Math.floor(Math.sqrt(array.size())), double histMin = 0, double histMax = 10) {
	float[] floatArray = new double[array.length];
	for (int i = 0 ; i < array.length; i++)
	{
	    floatArray[i] = (float) array[i];
	}
	return BBhistogram (floatArray, nBins, histMin, histMax)
}

def int[] BBhistogram (double[] array, int nBins = (int)Math.floor(Math.sqrt(array.size())), double histMin = 0, double histMax = 10) {
	float[] floatArray = new double[array.length];
	for (int i = 0 ; i < array.length; i++)
	{
	    floatArray[i] = (float) array[i];
	}
	return BBhistogram (floatArray, nBins, histMin, histMax)
}
