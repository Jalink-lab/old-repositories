#@ File (label="Select LIF file", style="file") lifFile


import loci.formats.ImageReader
import ij.IJ
import ij.ImagePlus

def main() {
	IR = new ImageReader()
	IR.setId(lifFile.toString())
	for (i=0;i<IR.getSeriesCount();i++){
		IR.setSeries(i)
		metaData = IR.getSeriesMetadata()
		if (!metaData.get("Image name").contains('/')){
			println "found it : "+metaData.get("Image name")
			imp = openImage(lifFile,i)
		}
	}
	IR.close()
}

def ImagePlus openImage(File lifFile,int ID) {
	IJ.run("Bio-Formats Importer", "open=["+lifFile.toString()+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+(ID+1))
	if (ij.WindowManager.getImageCount()==0){IJ.noImage();return;} 
	return ij.WindowManager.getCurrentImage()
}
main()