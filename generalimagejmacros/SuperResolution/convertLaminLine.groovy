#@ File (label="Select directory LaminLine.mat", style="directory") dirFiles
import ij.IJ
import ch.psi.imagej.hdf5.HDF5Reader //requires deinstallation of the HDF5_Vibez plugin, and installation of https://github.com/paulscherrerinstitute/ch.psi.imagej.hdf5
import ij.gui.PolygonRoi
import ij.gui.Roi
import ij.plugin.frame.RoiManager
import static groovy.io.FileType.* 

def void main(){
	dirFiles.eachFileRecurse {
		name = it.getName()
		if (name == 'LaminLine.mat') {
			convertLaminLine(it)
		}
	}
}
def void convertLaminLine(File matFile){
	IJ.run("Close All", "")
	println "converting "+matFile.toString()
	reader = new HDF5Reader()
	stack = reader.open("",false, matFile.toString(), "/myLine", true,true)
	pix = stack.getPixels(1)
	N = (int)(pix.size()/2)
	xpoints = new float[N]
	ypoints = new float[N]
	for (int i = 0;i<N;i++){
		xpoints[i] = pix[i]/10
		ypoints[i] = pix[N+i]/10
	}
	rm = RoiManager.getRoiManager()
	rm.reset()
	rm.addRoi(new PolygonRoi(xpoints,ypoints,N,Roi.POLYLINE));
	outFile = matFile.toString()
	outFile=outFile[0..outFile.size()-4]+'roi'
	rm.runCommand("Save", outFile);	
}
main()