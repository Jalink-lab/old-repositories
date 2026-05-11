#@ File (label="csv", style="file") laminCsv
#@ File (label="roi", style="file") laminRoi

import ij.IJ
import ij.plugin.frame.RoiManager

def void main(){
	showRoi(laminRoi, laminCsv)
}

def void showRoi(File laminRoi, File laminCsv){
	roiFile = "X:\\2019\\10\\28 (Leila-H3K9ac+VP16)\\Results-v2.41\\02-191028+VP16+LaminAA532_chromcorr.roi"
	IJ.run("Import results", "detectmeasurementprotocol=false filepath=["+laminCsv.toString()+"] fileformat=[CSV (comma separated)] livepreview=true rawimagestack= startingframe=1 append=false");
	IJ.run("Visualization", "imleft=0.0 imtop=0.0 imwidth=180.0 imheight=180.0 renderer=[Averaged shifted histograms] magnification=10.0 colorize=false threed=false shifts=2");
	rm = RoiManager.getRoiManager()
	rm.reset()
	rm.runCommand("Open", laminRoi.toString());	
	rm.runCommand("Show All");
}

main()