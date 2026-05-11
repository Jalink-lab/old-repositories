//first ask user to open a file and specify an output directory


//read the meta-data and make a list of all wells present
//e.g. B11, D12, C02 etc.


//go over the datasets and open only Colors, Intensity and FastFLIM


//Save as <wellname>-C <wellname>-I <wellname>-T

open("Z:/Sravasti/PDE SCREEN (1).lif");
run("Bio-Formats Macro Extensions"); 
Ext.setId("Z:/Sravasti/PDE SCREEN (1).lif"); 

Ext.getSeriesCount(nr_series); 
print(nr_series); 

for(s=1;s<nr_series;s=s+11) {	//iterate per 2
		if(nImages>0) run("Close All");
		print("Processing file "+PDE SCREEN (1).lif+", series "+s+11+"/"+nr_series+"...");
		run("Bio-Formats Importer", "open=["+PDE SCREEN (1).lif+"] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_" + (s,0));
}

//run("script:D:\Data\2019\05\02\blast_leicafile.ijm", "  color_mode=Default quiet rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_1 show");

//Ext.getSizeX(sizeX); 
//Ext.getSizeY(sizeY); 
//Ext.getPixelType(pixelType); 

















//selectWindow("PDE SCREEN (1).lif - B2");
//selectWindow("PDE SCREEN (1).lif - B2/FLIM/Intensity");
//selectWindow("PDE SCREEN (1).lif - B2/FLIM/Fast Flim");

//selectWindow("Z:/Sravasti/PDE SCREEN (1).lif - B2/FLIM/Intensity");
//selectWindow("Series 4:B2/FLIM/Intensity");
//color_mode=Default quiet rois_import=[ROI manager] 
//view=("Hyperstack stack_order=XYCZT series_1 series_4 series_5");

//run("color_mode=Default");
//run("quiet rois_import=[ROI manager]");
//run("view=Hyperstack");
//run("stack_order=XYCZT series_2 series_4 series_5 show");
