/* To start with imgLib2.
 *  There is an interface Img<T>. Img stores pixels and thus is the basis for conventional image processing.
 *  <T> is "generic typing" for the type of Img. Like 8-bit, 16-bit, 32-bit in original ImageJ
 *  
 *  An interface can be implemented in a Class, meaning that Class must support all the methods of the interface
 *  
 *  Step one is to obtain a Class that implements Img<T>
 */ 

import net.imglib2.Cursor // can go over an Img
import net.imglib2.type.Type
import net.imglib2.IterableInterval

def < T extends Comparable< T > & Type<T>> double percentile(IterableInterval<T> img, double p){
	N=img.size()
	cursorImg = img.cursor()
	inDat = new T[N] //an array of type T
	idx = (int) 0
	while ( cursorImg.hasNext())
	{
		// next() means move cursor forward and get the pixel
		inDat[idx] = cursorImg.next().copy() //get a copy of the pixel for the array
		idx++
	}
	Arrays.sort(inDat) //since T extends Comparable it can be sorted
	if (p<(0.5/N)){return (double) inDat[0].get()}
	if (p>((N-0.5)/N)){return (double) inDat[inDat.size()-1].get()}

	pIdx = (int) (p*N)
	res = (0.5-(p*((double) N))+pIdx)%1
	if (res<0){
		res++
		pIdx++
	}
	return inDat[pIdx].get()*(1-res)+inDat[pIdx-1].get()*(res)
}