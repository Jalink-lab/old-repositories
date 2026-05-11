#@ File    (label = "CSV input file", style = "file") srcFile
#@ File    (label = "CSV output file", style = "file") dstFile

import ij.IJ
import ij.measure.ResultsTable

def main() {
	// load xValues and yValues in double precision arrays
	resultsTableIn = new ResultsTable()
	resultsTableIn = resultsTableIn.open2(srcFile.toString())
	xName = "x [nm]"
	xIdx = resultsTableIn.getColumnIndex(xName)
	if (xIdx==-1){println "error, did not find $xname";return}
	xVals = resultsTableIn.getColumnAsDoubles(xIdx)
	yName = "y [nm]"
	yIdx = resultsTableIn.getColumnIndex(yName)
	if (xIdx==-1){println "error, did not find $yname";return}
	yVals = resultsTableIn.getColumnAsDoubles(yIdx)
	
	// get current image
	imp = IJ.getImage()
	imagePixelSize = pixelWidth = imp.getCalibration().pixelWidth
	imagePixelSize = imagePixelSize*1000 //um to nm
	// get ROI in image
	roi = imp.getRoi()
	
	// determine if point is in or out of the ROI
	pointIsIn = new boolean[xVals.size()]
	pointsIn = (int) 0
	for (int i=0;i<xVals.size();i++){
		pointIsIn[i]=roi.containsPoint(xVals[i]/imagePixelSize,(yVals[i]/imagePixelSize))
		if(pointIsIn[i]){pointsIn++}
	}
	println "found $pointsIn points in ROI" 
	// create output table
	resultsTableOut = new ResultsTable(pointsIn)
	headings = resultsTableIn.getHeadings()
	currentRow = (int) 0
	for (int i=0;i<xVals.size();i++){
		if(pointIsIn[i]){
			for (int col=0;col<resultsTableIn.getLastColumn();col++){
				resultsTableOut.setValue(headings[col],currentRow,resultsTableIn.getValue(headings[col],i))
			}
			currentRow++
		}
	}
	resultsTableOut.show("Results Table Out")
	resultsTableOut.save(dstFile.toString())
	return
}

main()