def double percentile(double[] inDat, double p){
	N=inDat.size()
	if (p<(0.5/N)){return inDat[0]}
	if (p>((N-0.5)/N)){return inDat[inDat.size()-1]}
	
	pIdx = (int) (p*N)
	res = (0.5-(p*((double) N))+pIdx)%1
	if (res<0){
		res++
		pIdx++
	}
	return inDat[pIdx]*(1-res)+inDat[pIdx-1]*(res)
}
double[] data = [0,1,2,3,4,5,6,7,8,9] 

println percentile(data,0.99) //should be 9
println percentile(data,0.01) //should be 0
println percentile(data,0.50) //should be 4.5 (median)
println percentile(data,0.51) //should be 4.6
println percentile(data,0.05) //should be 0
println percentile(data,0.95) //should be 9
double[] data2 = [15, 20, 35, 40, 50]
println percentile(data2,0.4) //should be 27.5
double[] data3 = [95.1772000000000,95.1567000000000,95.1937000000000,95.1959000000000,95.1442000000000,95.0610000000000,95.1591000000000,95.1195000000000,95.1065000000000,95.0925000000000,95.1990000000000,95.1682000000000]
Arrays.sort(data3)
println percentile(data3,0.90) //could be 95.1981 or 95.19683 depending on the implemented method (we have 95.19683)