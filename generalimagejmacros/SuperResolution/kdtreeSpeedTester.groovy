#@ File    (label = "CSV set 1 file", style = "file") set1File
#@ File    (label = "CSV set 2 file", style = "file") set2File
#@ File    (label = "CSV out file", style = "file") outFile

import com.opencsv.CSVReader
import com.opencsv.CSVWriter
import net.sf.javaml.core.kdtree.KDTree
/*
 * requires Java-ml
 * download from http://java-ml.sourceforge.net/
 * and put javaml-0.1.7.jar in /jars of fiji
 * 
 * Test data:
 * 107.489 points in set 1
 * 13.426 points in set 2
 * Question: For each point in set 2, what is its nearest neighbor in set 1
 * 4 tests:
 * Groovy brute force (135 seconds)
 * Groovy kd-tree (0.12 seconds)
 * Matlab brute force (7.44 seconds)
 * Matlab kd-tree (0.15 seconds)
*/

def main() {
	//Load Data
	String[] headerValues = ['x [nm]','y [nm]']
	data1 = readData(set1File,headerValues)
	data2 = readData(set2File,headerValues)
	println "Finished Reading Data"
	//kd-trees
	startTime = System.nanoTime();
	NN1 = kdTreeMethod(data1,data2)
	endTime = System.nanoTime();
	duration = (endTime - startTime);
	inmSec = ((double)duration)/1000000
	println "kd-tree took $inmSec milliseconds"

	//brute force
	startTime = System.nanoTime();
	NN2 = bruteForceMethod(data1,data2)
	endTime = System.nanoTime();
	duration = (endTime - startTime);
	inmSec = ((double)duration)/1000000
	println "brute force took $inmSec milliseconds"
	
	//write result
	FileWriter writer = new FileWriter(outFile);
	for (int j = 0; j < NN2.length; j++) {
	    writer.append(String.valueOf(NN2[j]));
	    writer.append("\n");
	}
	writer.close();
	return
}
def double[] bruteForceMethod(double[][] data1, double[][] data2){
	NN = new int[data2.length]
	d2 = (double) 0
	mind2 = (double) 0
	for (int i = 0; i<data2.length;i++){
		mind2 = Double.POSITIVE_INFINITY;
		for (int j = 0; j<data1.length;j++){
			d2 = (data1[j][0]-data2[i][0])*(data1[j][0]-data2[i][0])+(data1[j][1]-data2[i][1])*(data1[j][1]-data2[i][1])
			if (d2<mind2){
				mind2 = d2
				NN[i]=j
			}
		}
	}
	return NN
}

def double[] kdTreeMethod(double[][] data1, double[][] data2){
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

def double[][] readData(File file,String[] headerValues){
	//read all data
	CSVReader reader = new CSVReader(new FileReader(file))
	List<String[]> records = reader.readAll()
	N = reader.getLinesRead()-1 //single line header
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