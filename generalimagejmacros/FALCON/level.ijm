run("32-bit");
run("Clear Results");
sumOfMeans = 0
for (i = 1; i < 62; i++) {
	Stack.setFrame(i)
	run("Measure");	
	getStatistics(area, mean, min, max, std, histogram);
	sumOfMeans = sumOfMeans+mean;
}
meanOfMeans = sumOfMeans/61
print(meanOfMeans)
for (i = 1; i < 62; i++) {
	Stack.setFrame(i)
	run("Measure");	
	getStatistics(area, mean, min, max, std, histogram);
	factor = sumOfMeans/mean;
	run("Multiply...", "value="+factor+" slice");
}
run("8-bit");