pixelTable = "Pixel data";
Table.create(pixelTable);
row=0;

getRawStatistics(nPixels, mean, min, max, std, histogram);
for (i = 0; i < histogram.length; i++) {
	for (j = 0; j < histogram[i]; j++) {
		Table.set("cell", row, i, pixelTable);
		row++;
	}
}
Table.update;
