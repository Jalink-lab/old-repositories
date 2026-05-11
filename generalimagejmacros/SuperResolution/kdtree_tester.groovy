import net.sf.javaml.core.kdtree.KDTree
import ij.gui.Plot

//requires Java-ml
// download from http://java-ml.sourceforge.net/
// and put the .jar in /jar of fiji

def main() {
	//generate some random data
	N = (int) 10000
	xDat = new double[N]
	yDat = new double[N]
	key = new double[2]
	kdtree = new KDTree(2)
	for (int i =0;i<N;i++){
		xDat[i] = Math.random()
		yDat[i] = Math.random()
		key[0] = xDat[i]
		key[1] = yDat[i]
		kdtree.insert(key,i)
	}

	//location to search nearest neighbors for
	double[] loc = [0.5,0.5]
	found = kdtree.nearest(loc)
	println "found index $found"
	//make plot
	plot = new Plot("Some Points","xDat","yDat")
	plot.setColor("red")
	plot.addPoints(xDat,yDat,Plot.CIRCLE)
	plot.setColor("blue")
	plot.addPoints([xDat[found]],[yDat[found]],Plot.CIRCLE)
	plot.show()
	return
}

main()