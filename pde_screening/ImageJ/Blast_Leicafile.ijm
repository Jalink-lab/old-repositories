@File(label = "Input file", style = "file") inputFile
@File(label = "Output directory", style = "directory") outputDirectory


run("Bio-Formats Macro Extensions");
Ext.setId(inputFile);
Ext.getSeriesCount(seriesCount);
print(seriesCount);