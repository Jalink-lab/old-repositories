import ij.IJ
import ij.ImagePlus
import ij.plugin.frame.RoiManager
import ij.measure.ResultsTable
import ij.gui.Plot
import ij.measure.CurveFitter
import ij.plugin.ImageCalculator
import java.awt.Color

//I fitted the data with two lifetimes. 0.7 and 3.2 ns and the result is two intensity images
//For each ROI I want the normalized lifetime over time.

//v1.1
groovyPath = "E:/GitLab_Reps/generalimagejmacros/Toolbox" //contains reusable groovy code
framerate = 5			//seconds per frame
lifetime = [0.6,3.4]	//lifetimes of the two components
k=4						//Kd of EPAC sensor

def double[] getYDataFromFit(double[] xData, CurveFitter curveFitter){
	def yData = new double[xData.size()]
	def params = curveFitter.getParams()
	for (int i = 0;i<xData.size();i++){
		yData[i] = curveFitter.f(params,xData[i])
	}
	return yData
}

def int[] getindexFitRange(double[] meanYData){
	double[] PPP = [0,0] //index and maximum
	diffMeanYData = new double[dims[4]-1]
	for (int i=0;i<dims[4]-1;i++){ //find maximum in first 200 seconds
		if (i>0) {
			if (meanYData[i]==Double.NaN){
				meanYData[i]=meanYData[i-1]
			}
			diffMeanYData[i-1] = meanYData[i]-meanYData[i-1]
		}
		if (meanYData[i]>PPP[1] && i<(200/framerate)){ //only 200 seconds
			PPP[0]=i;
			PPP[1]=meanYData[i]
		}
	}
	double[] FKP = [0,0] //index and maximum
	for (int i=(int)PPP[0];i<(dims[4]-1);i++){
		if (diffMeanYData[i]>FKP[1]){
			FKP[0]=i;
			FKP[1]=diffMeanYData[i]
		}
	}
	//meanplot = new Plot(title+" - Mean plot","time(s)","lifetime(ns)")
	//meanplot.add("line",xData,meanYData)
	//meanplot.show()
	println("found PPP at $PPP")
	println("found FKP at $FKP")
	int[] indexFitRange = [PPP[0],FKP[0]]
	return indexFitRange
}


if (ij.WindowManager.getImageCount()==0){IJ.noImage();return;} 
imp = ij.WindowManager.getCurrentImage()
dims = imp.getDimensions();
title = imp.getTitle()
roiManager = RoiManager.getRoiManager()
nRoi = roiManager.getCount()
roiManager.deselect()
IJ.run("Set Measurements...", "mean redirect=None decimal=3")
IJ.showStatus("Doing MultiMeasure...")
resultsTable = roiManager.multiMeasure(imp)
//initial fit parameters
double[] initalParams = [2.5,-0.5,0.05,330]
//display data
plot = new Plot(title+" - Data plot","time(s)","lifetime(ns)")
fitsplot = new Plot(title+" - Fits plot","time(s)","lifetime(ns)")
//meanplot = new Plot(title+" - Mean plot","time(s)","lifetime(ns)")


//create new image displaying (intensity weighted) lifetime
//impLifetimes = imp.createImagePlus()
//impLifetimes.show()
//DO THIS IN IJ1 MACRO!!


//save parameters and goodness of fit
allFitData = new double[nRoi][initalParams.size()+1]
int nrNaNs = 0;
meanYData = new double[dims[4]]
for (int roi=0;roi<nRoi;roi++) {
	IJ.showStatus("Fitting Data ("+roi+"/"+nRoi+")")
	IJ.showProgress(roi,nRoi)
	columnData = resultsTable.getColumnAsDoubles(roi)
	xData = new double[columnData.size()/2-1]	//ignore last (partial) frame, hence -1
	yData = new double[columnData.size()/2-1]
	nrNaNs=0;
	for (int fr=0;fr<(columnData.size()/2-1);fr++){
		M1 = columnData[fr*2]   //intensity weighted contribution
		M2 = columnData[1+fr*2] //intensity weighted contribution
		//M1a = M1/lifetime[0]    //amplitude weighted, scales with [EPAC] (free epac, low lifetime)
		//M2a = M2/lifetime[1]    //amplitude weighted, scales with [cAMP_EPAC]
		xData[fr] = fr*framerate //time axis
		yData[fr] = (M1*lifetime[0] + M2*lifetime[1])/(M1+M2) //lifetime
		meanYData[fr]  = meanYData[fr] + (yData[fr]/nRoi)
		//yData[fr] = k*(M2a/M1a)
		if(yData[fr]==Double.NaN){
			yData[fr]=0
			nrNaNs++;
		}
	}
	if(nrNaNs > 0) println(nrNaNs + " NaNs found in ROI " + roi + 1)

	indexFitRange = getindexFitRange(meanYData)
	double[] xDataTrimmed = xData[indexFitRange[0]..indexFitRange[1]]
	double[] yDataTrimmed = yData[indexFitRange[0]..indexFitRange[1]]
	curveFitter = new CurveFitter(xDataTrimmed,yDataTrimmed)
	curveFitter.doCustomFit("y=a + b/(1+exp(-c*(x-d)))", initalParams, false)
	params = curveFitter.getParams()
	allFitData[roi][0] = params[0]
	allFitData[roi][1] = params[1]
	allFitData[roi][2] = params[2]
	allFitData[roi][3] = params[3]
	allFitData[roi][4] = curveFitter.getRSquared()
	
	yDataFit = getYDataFromFit(xData,curveFitter)
	rgb = new float[3]
	rgb[0] = Math.random()
	rgb[1] = Math.random()
	rgb[2] = Math.random()
	color2 = new Color((float)rgb[0], (float)rgb[1],(float)rgb[2])
	color1 = new Color((float)(rgb[0]/2), (float)(rgb[1]/2),(float)(rgb[2]/2))
	plot.setColor(color1,color2)
	plot.add("connected circle",xData,yData)
//	fitsplot.setColor(color2)
//	fitsplot.add("line",xData,yDataFit)
	plot.setColor(color2)
	plot.add("line",xData,yDataFit)
}
plot.show()
plot.setLimitsToFit(true)
double[] limits = plot.getLimits()

//fitsplot.show()
fitsplot.setLimits(limits)
fitsplot.update()



resultsTable = new ResultsTable(nRoi)
for (int roi=0;roi<nRoi;roi++){
	resultsTable.setValue(0,roi,allFitData[roi][4])
}
resultsTable.show("Results")
//double[] limits = [0,600,2,3.2]
//plot.setLimits(limits)
//plot.update()