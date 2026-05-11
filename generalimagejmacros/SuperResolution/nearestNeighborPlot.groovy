#@ File    (label = "CSV set 1 file", style = "file") set1File
#@ File    (label = "CSV set 2 file", style = "file") set2File

import com.opencsv.CSVReader
import net.sf.javaml.core.kdtree.KDTree
import ij.gui.Plot

/*
 * requires Java-ml
 * download from http://java-ml.sourceforge.net/
 * and put the .jar in /jar of fiji
 * 
 * Plot the nearest neighbor distribution from all points in set 2 to set 1
*/
def main() {
	String[] headerValues = ['x [nm]','y [nm]']
	data1 = readData(set1File,headerValues)
	data2 = readData(set2File,headerValues)
	NN = nearestNeighbors(data1,data2)
	distances = getDistances(data1,data2,NN)
	plot = new Plot("distances","xlabel","ylabel")
	plot.add("circle",distances)
	plot.show()
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