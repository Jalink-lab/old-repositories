#@ File    (label = "Input CSV file", style = "file") inputFile
#@ File    (label = "Output CSV file", style = "file") outputFile

// https://imagej.net/Script_Parameters to read about using scripting parameters like we do in line 1&2


/* ThunderSTORM stores files as comma seperated values or CSV. 
 *  ThunderSTORM can open and save them with the following commands:
 */
 
import ij.IJ //we import ImageJ. From now on, if we type IJ it means the library we imported.
IJ.run("Import results", "detectmeasurementprotocol=false filepath=["+inputFile.toString()+"] fileformat=[CSV (comma separated)] livepreview=true rawimagestack= startingframe=1 append=false");
IJ.run("Show results table", "action=filter formula=[x > 10000]"); //keep only if x > 10000 nm
IJ.run("Export results", "floatprecision=5 filepath=["+outputFile.toString()+"] fileformat=[CSV (comma separated)] sigma=true intensity=true chi2=true offset=true saveprotocol=false x=true y=true bkgstd=true id=true uncertainty_xy=true frame=true detections=true");

// exercise 1: remove the localizations that have an uncertainty bigger than 15nm
// exercise 2: automatically run it on a whole folder (hint: there is a groovy template in ImageJ 1.x to process a folder with images.) 