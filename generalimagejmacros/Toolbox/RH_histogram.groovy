import net.imglib2.type.Type
import net.imglib2.IterableInterval
import net.imglib2.img.array.ArrayImgFactory
import net.imglib2.type.numeric.real.FloatType
import net.imglib2.type.numeric.IntegerType

def < T extends Comparable< T > & Type<T>> int[] histogram(IterableInterval<T> img, int nBins=-1, double minVal = Double.NaN, double maxVal = Double.NaN){
	//if nBins is not set, create it
	if (nBins==-1){
		nBins = Math.floor(Math.sqrt(img.size()))
	}
	//if minVal or maxVal is not given we must find it in the data
	if (minVal==Double.NaN||maxVal==Double.NaN){
		minTemp = img.firstElement().createVariable()
		maxTemp = img.firstElement().createVariable()
		for (i in img){
			if ( i.compareTo( minTemp ) < 0 )
                minTemp.set( i );
 
            if ( i.compareTo( maxTemp ) > 0 )
                maxTemp.set( i );
		}
		if(minVal==Double.NaN){minVal = minTemp.get()}
		if(maxVal==Double.NaN){maxVal = maxTemp.get()}
	}
	
	//we have nBins, minVal and maxVal. Let's construct the edges
	step = (maxVal-minVal)/nBins
	factory = new ArrayImgFactory<>(img.firstElement().createVariable())
	int[] dimensions = [1,nBins+1]
	edges = factory.create(dimensions)
	randomA = edges.randomAccess()
	for (int i = 0;i<(nBins+1);i++){
		if (IntegerType.isInstance(img.firstElement())){
			randomA.get().set((int) (minVal+i*step)) //This should only be cast to int when T is IntegerType
		}else {
			randomA.get().set((minVal+i*step)) 
		}
		randomA.fwd(1)
	}
	return histogram(img,edges)
}

//compares the values in img to values in edges. must have same type.
def < T extends Comparable< T > & Type<T>> int[] histogram(IterableInterval<T> img, IterableInterval<T> edges){
	final bins = new int[edges.size()-1]
	final temp = img.firstElement().createVariable()
	final int binIndex = 0
	for (i in img ){
		binIndex = 0
		temp = i.get()
		for (e in edges ){
			if (temp.compareTo(e.get())<0){
				if(binIndex==0){continue}
				bins[binIndex-1]++
				continue
			}
			binIndex++
		}
	}
	return bins
}