#@ File (label="Select directory with 2-component data", style="directory") dirTwoComponents
#@ File (label="Select directory with ROI data", style="directory") dirROI
#@ File (label="Select output directory", style="directory") outDir
#@ Double(label="Frame Rate(sec/frame)",value=5) framerate
#@ Double(label="Lifetime 1(ns)",value=0.6) tau1
#@ Double(label="Lifetime 2(ns)",value=3.4) tau2
#@ Double(label=="Stability range(ns)",value=0.2) stabilityRange
#@ Boolean(label="Remove last frame",value=true) removeLastFrame

/* -- ANALYSE DATA FROM CAGED CAMP SCREEN --
 *  Difference from the chemical screen is that there will be no FKP or PPP
 *  Need to know the maximum
 *  Fit something on the falling flank
 */

import ij.IJ //ImageJ
import static groovy.io.FileType.* //to be able to call FILES, DIRECTORIES or ANY
import ij.plugin.frame.RoiManager
import ij.measure.ResultsTable
import ij.gui.Plot
import ij.measure.CurveFitter
import java.awt.Color
import com.opencsv.CSVWriter

def main() {
	File csvFile = new File(outDir, "AllResult.tsv");
	CSVWriter writer = new CSVWriter(new FileWriter(csvFile), (char)'\t')
	header = "Well#N#Mean#Standard Deviation#5 percentile#25 percentile#50 percentile#75 percentile#95 percentile".split("#")
	writer.writeNext(header)
	dirTwoComponents.eachFileMatch FILES, ~".*.tif", {//When File is a folder it can iterate over all files in a loop. In the loop the individual files are called 'it'
		// The ~ creates a java.util.regex.Matcher . = any character * = any nr of times, but ending must be .tif (so it is an extension matcher)
		def well = it.name //first 3 characters
		well = well[0..(well.size()-5)] //entire name without .tif
		println well
		if (well.endsWith("_")){well=well[0..1]} //if last is _ remove it
		openFile(it,well)
		ft = getLifetimesFromROI() //returns a FancyTable class
		ft.show()
		ft.save(outDir.toString()+"/"+well+"_ROIData.tsv")
		ft = getindexFitRange(ft)
		allFitData=fitLifetimes(ft)
		selectedFitData = filterFitData(allFitData)
		selectedFitData.show("Results")
		showAllInPlot(selectedFitData,ft)
		statsMidpoint = getStatsColumn(selectedFitData,3)
		println "Statistics for $well"
		println "Mean = "+statsMidpoint[0].toString()
		println "Std = "+statsMidpoint[1].toString()
		selectedFitData.save(outDir.toString()+"/"+well+"_fitresults.tsv")
		String[] outData = new String[statsMidpoint.size()+1]
		outData[0]=well
		for (int i=0;i<statsMidpoint.size();i++){
			outData[i+1]=statsMidpoint[i]
		}
		writer.writeNext(outData)
	} 
	writer.close()	
}

def openFile(fileTwoCP,well) { //match .tif file to the .zip file
	def fileROI = new File("")
	dirROI.eachFileMatch FILES, ~".*$well.*.zip",{fileROI=it}
	println "Processing:\n$fileTwoCP\n$fileROI\n--------"
	IJ.run("Close All", "");
	def imp = IJ.openImage(fileTwoCP.toString())
	imp.show()
	rm = RoiManager.getRoiManager()
	rm.reset()
	rm.runCommand("Open", fileROI.toString())
	rm.show()
}
def double[] getStatsColumn(ResultsTable rt,int col){
	//N, mean, std, 5% 25% 50% 75% 95%
	double[] out = [0,0,0,0,0,0,0,0]
	colDat = rt.getColumnAsDoubles(col)
	//N
	out[0]=colDat.size()
	Arrays.sort(colDat)
	//5% 25% 50% 75% 95%
	out[3] = percentile(colDat,0.05)
	out[4] = percentile(colDat,0.25)
	out[5] = percentile(colDat,0.50)
	out[6] = percentile(colDat,0.75)
	out[7] = percentile(colDat,0.95)
	
	//mean
	double sumDat = 0
	for (int i = 0;i<out[0];i++){
		sumDat+=colDat[i]
	}
	out[1] = sumDat/out[0]
	//std
	double varDat = 0
	for (int i = 0;i<out[0];i++){
		varDat+=(out[0]-colDat[i])*(out[0]-colDat[i])
	}
	out[2] = Math.sqrt(varDat/out[0])
	return out
}

def double percentile(double[] inDat, double p){
	N=inDat.size()
	if (p<(0.5/N)){return inDat[0]}
	if (p>((N-0.5)/N)){return inDat[inDat.size()-1]}
	for (int i=1;i<(inDat.size()+1);i++){
		currPercentile = (i-0.5)/N
		if(currPercentile>=p){
			res = (currPercentile-p)*N
			return inDat[i-1]*(1-res)+inDat[i-2]*(res)
		}
	}
	return -1 //should never happen
}

def FancyTable getLifetimesFromROI() {
	rm = RoiManager.getRoiManager()
	IJ.run("Set Measurements...", "mean redirect=None decimal=3")
	IJ.showStatus("Doing MultiMeasure...")
	imp = ij.WindowManager.getCurrentImage()
	resultsTableIn = rm.multiMeasure(imp)
	resultsTableIn.show()
	def nFr = imp.getNFrames()
	if (removeLastFrame){nFr=nFr-1}
	nRoi = rm.getCount()
	lifetime = new ResultsTable(nFr)
	intensity = new ResultsTable(nFr)
	for (int fr=0;fr<nFr;fr++){
		 intensity.setValue("Time(s)",fr,fr*framerate) //column, row, value
		 lifetime.setValue("Time(s)",fr,fr*framerate) //column, row, value
		 for (int roi=0;roi<nRoi;roi++){
		 	M1 = resultsTableIn.getValueAsDouble(roi, fr*2) //intensity first channel
		 	M2 = resultsTableIn.getValueAsDouble(roi, 1+fr*2) //intensity second channel
		 	intensity.setValue("ROI $roi Int",fr,M1+M2) //column, row, value
		 	tau = (M1*tau1 + M2*tau2)/(M1+M2);
		 	if (tau==0){tau=Double.NaN;}
		 	lifetime.setValue("ROI $roi Tau",fr,tau) //column, row, value
		 }
	}
	ft = new FancyTable()
	ft.setLifetime(lifetime)
	ft.setIntensity(intensity)
	return ft
}
def showAllInPlot(ResultsTable fitData, FancyTable ft){
	//show the selected data in a plot
	plot = new Plot("Debug - Data plot","time(s)","lifetime(ns)")
	nRoi = fitData.size()
	xData = ft.getTimeAxis()
	xDataI = interpolateData(xData,1000)	
	params = new double[4]
	for (int roi=0;roi<nRoi;roi++){
		roiIdx = fitData.getValue("Roi",roi)
		yData = ft.getLifetimeAsDouble((int)roiIdx)
		//extract params
		params[0] = fitData.getValue("start(ns)",roi)
		params[1] = fitData.getValue("range(ns)",roi)
		params[2] = 1/fitData.getValue("rate(s)",roi)
		params[3] = fitData.getValue("midpoint(s)",roi)
		yDataFit = getYdataFromParams(xDataI,params)
		rgb = new float[3]
		rgb[0] = Math.random()
		rgb[1] = Math.random()
		rgb[2] = Math.random()
		color2 = new Color((float)rgb[0], (float)rgb[1],(float)rgb[2])
		color1 = new Color((float)(rgb[0]/2), (float)(rgb[1]/2),(float)(rgb[2]/2))
		plot.setColor(color1,color2)
		plot.add("connected circle",xData,yData)
		plot.setColor(color2)
		plot.add("line",xDataI,yDataFit)
	}
	plot.show()
}
def double[] interpolateData(double[] inData,int N){
	outData = new double[N]
	start = inData[0]
	end = inData[inData.size()-1]
	range = end-start
	step = range/N
	outData[0]=start
	for (int i=1;i<N;i++){
		outData[i]=outData[i-1]+step
	}
	return outData
}

def ResultsTable filterFitData(ResultsTable allFitData){
	//start between 2.8 3.3
	nRoi = allFitData.size()
	badRSq = (int)0   //counter for nr of ROIs deleted for having a too low R-squared
	badStart = (int)0 //counter for nr of ROIs deleted for having an out of range starting point
	for(int roi=(nRoi-1);roi>-1;roi--){ // go backwards because deletion shifts rows upwards
		startOfFit = allFitData.getValue("start(ns)",roi)
		RSq = allFitData.getValue("RSq",roi)
		deleteROI = false
		if (startOfFit>3.3||startOfFit<2.8){
			deleteROI = true
			badStart++
		}
		if (RSq<0.95){
			deleteROI = true
			badRSq++
		}
		if (deleteROI){allFitData.deleteRow(roi)}
	}
	deleted = nRoi-allFitData.size()
	remaining = allFitData.size()
	println "deleted $deleted ROIs"
	println "deleted $badStart for out of range starting point"
	println "deleted $badRSq for low R-squared"
	println "$remaining ROIs remain"
	return allFitData
}

def ResultsTable fitLifetimes(FancyTable ft){
	double[] initalParams = [2.5,-0.5,0.05,120]
	indexFitRange = ft.getFitRange()
	validROIs = ft.getValidROIs()
	nFr = ft.getNFr() //nRows
	nRoi = ft.getNRoi() //0-indexed
	allFitData = new ResultsTable()
	//start fitting
	xData = ft.getTimeAxis()
	double[] xDataTrimmed = xData[indexFitRange[0]..indexFitRange[1]]
	int roiIdx = 0;
	for (int roi=0;roi<nRoi;roi++){
		if (!validROIs[roi]){continue}
		IJ.showStatus("Fitting Data ("+roi+"/"+nRoi+")")
		IJ.showProgress((int) roi,(int) nRoi)
		yData = ft.getLifetimeAsDouble(roi)
		double[] yDataTrimmed = yData[indexFitRange[0]..indexFitRange[1]]
		curveFitter = new CurveFitter(xDataTrimmed,yDataTrimmed)
		curveFitter.doCustomFit("y=a + b/(1+exp(-c*(x-d)))", initalParams, false)
		params = curveFitter.getParams()
		allFitData.setValue("Roi",roiIdx,roi)
		allFitData.setValue("start(ns)",roiIdx,params[0])
		allFitData.setValue("range(ns)",roiIdx,params[1])
		allFitData.setValue("rate(s)",roiIdx,1/params[2])
		allFitData.setValue("midpoint(s)",roiIdx,params[3])
		allFitData.setValue("RSq",roiIdx,curveFitter.getRSquared())
		allFitData.setValue("RMSE",roiIdx,getRMSE(curveFitter.getResiduals()))
		allFitData.setValue("Intensity",roiIdx,ft.getMeanIntesityOfROI(roi))
		roiIdx++
	}
	return allFitData
}
def double[] getYdataFromParams(double[] xData,double[] params){
	def yData = new double[xData.size()]
	for (int i = 0;i<xData.size();i++){
		//"y=a + b/(1+exp(-c*(x-d)))"
		yData[i] = params[0] + params[1]/(1+Math.exp(-params[2]*(xData[i]-params[3])))
	}
	return yData
}
def double getRMSE(double[] residuals){
	double out = 0
	for (int i = 0;i<residuals.size();i++){
		out = out+(residuals[i]*residuals[i])
	}
	out = Math.sqrt(out/residuals.size())
}

//helper function for debug
def double[] getYDataFromFit(double[] xData, CurveFitter curveFitter){
	def yData = new double[xData.size()]
	def params = curveFitter.getParams()
	for (int i = 0;i<xData.size();i++){
		yData[i] = curveFitter.f(params,xData[i])
	}
	return yData
}

def FancyTable getindexFitRange(FancyTable ft){
	nFr = ft.getNFr() //nRows
	nRoi = ft.getNRoi() //0-indexed
	//get mean tau for fit range
	meanTau = ft.getMeanLifetime()
	meanStart = (meanTau[0]+meanTau[1]+meanTau[2]+meanTau[3])/4 //mean over first 20 seconds
	validROIs = new boolean[nRoi]
	lifetime = new double[nFr]
	for (int roi=0;roi<nRoi;roi++){
		lifetime = ft.getLifetimeAsDouble(roi)
		validROIs[roi]=true 
		for (int fr=0;fr<4;fr++){
			if(lifetime[fr]>(meanStart+stabilityRange)||lifetime[fr]<(meanStart-stabilityRange)||lifetime[fr]==Double.NaN){
				validROIs[roi]=false //ROIs are not valid if they go outside of the stability range
			}
		}
	}
	ft.setValidROIs(validROIs)
	double[] PPP = [0,0] //index and maximum (x and y value. time and lifetime)
	diffmeanTau = new double[meanTau.size()-1] //important for the FKP 
	for (int i=0;i<diffmeanTau.size();i++){ //find maximum in first 200 seconds
		if (i>0) {
			if (meanTau[i]==Double.NaN){
				meanTau[i]=meanTau[i-1]
			}
			diffmeanTau[i-1] = meanTau[i]-meanTau[i-1]
		}
		if (meanTau[i]>PPP[1] && i<(200/framerate)){ //only 200 seconds
			PPP[0]=i;
			PPP[1]=meanTau[i]
		}
	}
	
	double[] FKP = [meanTau.size()-1,0] //index and maximum
	/*
	for (int i=(int)PPP[0];i<diffmeanTau.size();i++){
		if (diffmeanTau[i]>FKP[1]){
			FKP[0]=i;
			FKP[1]=diffmeanTau[i]
		}
	}
	*/
	FKP[1]=meanTau[(int)FKP[0]]
	meanplot = new Plot("Debug - Mean plot","time(s)","lifetime(ns)")
	meanplot.add("line",ft.getTimeAxis(),meanTau)
	double[] xVal = [PPP[0]*framerate,(FKP[0]-2)*framerate]
	double[] yVal = [PPP[1],meanTau[(int)(FKP[0]-2)]]
	meanplot.setColor("red")
	meanplot.addPoints(xVal,yVal,Plot.CIRCLE)
	meanplot.show()
	println("DEBUG: found PPP at $PPP")
	println("DEBUG: found FKP at $FKP")
	
	int[] indexFitRange = [PPP[0],FKP[0]-2] //two points
	ft.setFitRange(indexFitRange)
	return ft
}
/*
* FancyTable is a badly-named class that aims to simplify data handeling for lifetime and intensity data
* It contains two tables to store the data:
* - A results table for lifetimes with nRows for time and nCols for ROIs
* - A results table for intensities (same layout)
* Additionaly it stores the following:
* - Number of frames
* - Number of ROIs
* - A boolean array to indicate valid ROIs
* - A integer array to indicate the fit range indices []
* It has a few usefull methods
* - getTimeAxis()
* - getMeanLifetime()
* - getMeanIntensity()
* - getLifetimeAsDouble(int roi)
* - getMeanIntesityOfROI(int roi)
*/
class FancyTable{
	ResultsTable lifetime
	ResultsTable intensity
	int nFr = -1
	int nRoi = -1
	boolean[] validROIs
	int[] fitRange
	public void save(String path){
		lifetime.save(path[0..path.size()-5]+"_lifetime.tsv")
		intensity.save(path[0..path.size()-5]+"_intensity.tsv")
	}
	public void show(){ //just parse the command to the results table
		lifetime.show("lifetime")
		intensity.show("intensity")
	}
	public double[] getMeanLifetime(){
		return calculateMean(lifetime)
	}
	public double[] getMeanIntensity(){
		return calculateMean(intensity)
	}
	public double getMeanIntesityOfROI(int roi){
		double out = 0
		int validVal = 0
		double[] roiIntensities = getIntensityAsDouble(roi);
		for (int fr=0;fr<nFr;fr++){
			if(roiIntensities[fr]!=Double.NaN){
				validVal++
				out=out+roiIntensities[fr]
			}
		}
		out = out/validVal
		return out
	}
	public int getNFr(){
		return nFr
	}
	public int getNRoi(){
		return nRoi
	}
	public double[] getLifetimeAsDouble(int roi){
		return lifetime.getColumnAsDoubles(1+roi)
	}
	public double[] getIntensityAsDouble(int roi){
		return intensity.getColumnAsDoubles(1+roi)
	}
	public double[] getTimeAxis(){
		return lifetime.getColumnAsDoubles(0)
	}
	/*
	public ResultsTable getLifetime(){ //direct access to the table should normally not be needed
		return lifetime
	}
	public ResultsTable getIntensity(){ //direct access to the table should normally not be needed
		return intensity
	}
	*/
	public setLifetime(ResultsTable lifetime){
		this.lifetime=lifetime
		this.nFr = lifetime.size()
		this.nRoi = lifetime.getLastColumn()
	}
	public setIntensity(ResultsTable intensity){
		this.intensity=intensity
		this.nFr = intensity.size()
		this.nRoi = intensity.getLastColumn()
	}
	public boolean[] getValidROIs(){
		return validROIs
	}
	public setValidROIs(boolean[] vr){
		this.validROIs = vr
	}
	public int[] getFitRange(){
		return fitRange
	}
	public setFitRange(int[] fr){
		this.fitRange = fr
	}
	private double[] calculateMean(ResultsTable rt){
		double[] meanVal = new double[nFr]
		double[] validVal = new double[nFr]
		double temp = 0
		for (int roi=0;roi<nRoi;roi++){
			for (int fr=0;fr<nFr;fr++){
				temp = rt.getValueAsDouble(roi+1,fr)//first column is time
				validVal[fr]++
				if(temp==Double.NaN){
					temp=0
					validVal[fr]-- //needed to calculate the mean
				}
				meanVal[fr]=meanVal[fr]+temp
			}
		}
		for (int fr=0;fr<nFr;fr++){
			meanVal[fr]=meanVal[fr]/validVal[fr] //mean = sum/N
		}
		return meanVal
	}
}

main() //entry point of the script