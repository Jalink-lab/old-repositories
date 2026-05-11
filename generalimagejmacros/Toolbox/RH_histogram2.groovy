def int[] histogram(double[] values, double binWidth, double min, double max){
	double value = 0
	idx = new int[values.size()] //bin indices for all values
	int idxI = 0
	for (int i=0;i<values.size();i++){
		value = values[i]
		if (value<min||value>max){continue}
		value = value-min
		idx[idxI] = (int) value/binWidth //floor
		idxI++
	}
	nBins = (int) ((max-min)/binWidth)
	return cumSumIdx(idx,nBins+1,idxI)
}

def int[] cumSumIdx(int[]idx, int nBins, int idxI=idx.size()){ //make sure max(idx) < nBin
	outVal = new int[nBins]
	for (int i=0;i<idxI;i++){
		outVal[idx[i]]++
	}
	return outVal
}