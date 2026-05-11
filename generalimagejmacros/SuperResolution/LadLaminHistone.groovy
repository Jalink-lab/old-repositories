#@ File (label="Select directory", style="directory") mainDirectory

import com.opencsv.CSVReader
import com.opencsv.CSVWriter
import net.sf.javaml.core.kdtree.KDTree
import java.text.DecimalFormat
import ij.plugin.frame.RoiManager

/*Purpose:
 * Calculate the required distances and output them as .csv
 * - Point to the right directory and name the three files.
 * - 
 * Collect right .csv files from folders
 *  - X:\2019\analysis\sept_oct_LAD_Histone\HT1080-VP16
 *  - 
 */
def main() {
	mainDirectory.eachFileRecurse {
		name = it.getName()
		if (name == 'Histone647.csv') {
			fullname = it.toString()
			ladFile = new File(fullname.replace('Histone647.csv','LAD488.csv'))
			laminFile = fullname.replace('Histone647.csv','LaminLine.roi')
			outFile = new File(fullname.replace('Histone647.csv','distanceOut.csv'))
			processFiles(it,ladFile,laminFile,outFile)
		}
	}
}

def void processFiles(File hisFile, File ladFile, String laminFile, File outFile){
	println 'Starting on'
	println hisFile
	println ladFile
	println laminFile
	//get nearest neighbor from l
	String[] headerValues = ['x [nm]','y [nm]']
	hisDat = readData(hisFile,headerValues)
	ladDat = readData(ladFile,headerValues)
	NN = nearestNeighbors(hisDat,ladDat) //from dataset 2 to dataset 1
	distLad2His= getDistances(hisDat,ladDat,NN)
	// get distance from lad to lamin
	rm = RoiManager.getRoiManager()
	rm.reset()
	rm.runCommand('open',laminFile)
	laminRoi = rm.getRoi(0)
	laminLine = laminRoi.getInterpolatedPolygon(1, true) //interpolate every nm
	lamDat = new double[laminLine.xpoints.size()][2]
	for (int i=0;i<laminLine.xpoints.size();i++){
		lamDat[i][0] = laminLine.xpoints[i]
		lamDat[i][1] = laminLine.ypoints[i]
	}
	
	NN = nearestNeighbors(lamDat,ladDat)
	distLad2Lam= getDistances(lamDat,ladDat,NN)
	data = new double[ladDat.size()][2]
	for (int i = 0;i<ladDat.size();i++){
		data[i][0]=distLad2His[i]
		data[i][1]=distLad2Lam[i]
	}
	df = new DecimalFormat[2]
	df[0] = new DecimalFormat('#.####')
	df[1] = new DecimalFormat('#.#')
	headerValues = new String[2]
	headerValues[0] = 'Distance from LAD localization to nearest Histone localization(nm)'
	headerValues[1] = 'Distance from LAD localization to Lamin(nm)'
	writeData(outFile,data,headerValues,df)
	println "FINISHED"
}

def double[] getDistances(double[][] data1, double[][] data2,int[] NN){
	distances = new double[data2.length]
	for (int i = 0;i<data2.length;i++){
		distances[i] = Math.sqrt((data1[NN[i]][0]-data2[i][0])*(data1[NN[i]][0]-data2[i][0])+(data1[NN[i]][1]-data2[i][1])*(data1[NN[i]][1]-data2[i][1]))
	}
	return distances
}

def int[] nearestNeighbors(double[][] data1, double[][] data2){
	kdtree = new KDTree(2) // 2 dimensional kd-tree
	for (int i =0;i < data1.length;i++){
		kdtree.insert(data1[i],i) //construct the tree with i as the value
	}	
	NN = new double[data2.length]
	for (int i =0;i < data2.length;i++){
		NN[i] = kdtree.nearest(data2[i]) //get index of nearest neighbor
	}	
	return NN
}

def void writeData(File file,double[][] data, String[] headerValues,DecimalFormat[] df){
	CSVWriter writer = new CSVWriter(new FileWriter(file))
	writer.writeNext(headerValues)
	entry = new String[headerValues.size()]
	for (int i=0;i<data.size();i++){
		for (int j=0;j<headerValues.size();j++){
			entry[j]=df[j].format(data[i][j])
		}
		writer.writeNext(entry,false)
	}
	writer.close()
}

def double[][] readData(File file,String[] headerValues){
	//read all data
	CSVReader reader = new CSVReader(new FileReader(file))
	List<String[]> records = reader.readAll()
	N = reader.getLinesRead()-1 //single line header
	reader.close()
	data = new double[N][headerValues.size()]
	Iterator<String[]> iterator = records.iterator();
	
	//read header and search for requested values
	String[] record = iterator.next(); 
	idx = new int[headerValues.size()]
	for (int j = 0;j<headerValues.size();j++){
		idx[j] = -1
		for (int i = 0;i<record.size();i++){
			if (record[i]==headerValues[j]){
				idx[j]=i
			}
		}
		if (idx[j]==-1){
			throw new Exception("The header value "+headerValues[j]+" was not found")
		}
	}
	//put data
	for (int i = 0;i<N;i++){
		record = iterator.next();
		for (int j =0;j<headerValues.size();j++){
			data[i][j] = record[idx[j]].toDouble()
		}
	}
	return data	
}
main()