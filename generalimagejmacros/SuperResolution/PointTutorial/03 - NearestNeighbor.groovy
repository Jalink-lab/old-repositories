#@ File    (label = "CSV set 1 file", style = "file") set1File
#@ File    (label = "CSV set 2 file", style = "file") set2File

/* Example 3 : Load two datasets and get the nearest neighbor (NN) in the other set
 *  In this example we make use of so-called "methods" to structure the code a bit.
 *  The previous example is put below as "readData" and called two times in the main method to open the two datafiles.
 *  There is more to read about methods: https://www.tutorialspoint.com/groovy/groovy_methods.htm
 *  At the end of the script we run the method called "main" that is defined in line 28
  
 *  Steps in the script:
 *  1) import both datasets
 *  2) make a KD-tree for the one you want to find the NNs in
 *  3) find the NN using the locations in the other dataset
 *  4) calculate the distance
 *  5) put it in resultsTable for future processing
 */

import com.opencsv.CSVReader
import net.sf.javaml.core.kdtree.KDTree
import ij.measure.ResultsTable

/*
 * This demo requires Java-ml
 * download from http://java-ml.sourceforge.net/
 * and put the .jar in /jar of fiji
*/

def main() {
	String[] headerValues = ['x [nm]','y [nm]']
	data1 = readData(set1File,headerValues)
	data2 = readData(set2File,headerValues)
	NN = nearestNeighbors(data1,data2)
	distances = getDistances(data1,data2,NN)
	resultsTable = ResultsTable.getResultsTable() //reference to the ResultsTable used by the analyse/measure command.
	for (int i = 0;i<distances.length;i++){
		resultsTable.setValue(0,i,distances[i])
	}
	resultsTable.show("Results")
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