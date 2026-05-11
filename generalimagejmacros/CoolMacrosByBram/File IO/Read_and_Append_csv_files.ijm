/*
 * Macro to merge csv files.
 * Bram van den Broek, |The Netherlands Cancer Institute, 2019
 * 
 */


print("\\Clear");
run("Clear Results");
run("Input/Output...", "save_column");

//Find all result files in directory
dir = getDirectory("Choose a directory containing the .csv files");
showStatus("reading directory");
file_list = getFileList(dir); //get filenames of directory
showStatus("");

//make a list of images with 'extension' as extension.
j=0;
textfile_list=newArray(file_list.length);
for(i=0; i<file_list.length; i++){
	if (endsWith(file_list[i],".csv")) {
		textfile_list[j] = file_list[i];
		j++;
	}
}
textfile_list = Array.trim(textfile_list, j);	//Trimming the array of images
if(textfile_list.length==0) exit("No .csv files found");
else print("Experiment contains "+textfile_list.length+" .csv files:");

//Get column headers from the first file in the list
text_file = File.openAsString(dir+textfile_list[0]);
lines = split(text_file,"\n");
headers = split(lines[0],",");

//import all results into the results window and save
j=1;
m=0;
for(i=0; i<textfile_list.length; i++) {
	print("appending file: "+textfile_list[i]);
	text_file = File.openAsString(dir+textfile_list[i]);
	lines = split(text_file,"\n");
	for(j=1;j<lines.length;j++) {
		values = split(lines[j],",");
//		if(j==1) setResult("filename",m,substring(textfile_list[i], 0, lengthOf(textfile_list[i])-12));	//Only print file name at the first occurrance
//		else setResult("filename",m,"");
		setResult("filename",m,substring(textfile_list[i], 0, lengthOf(textfile_list[i])-4));
		for(k=0;k<headers.length;k++) {
			setResult(headers[k],m,parseFloat(values[k]));
		}
		m++;
	}
	updateResults();
}
selectWindow("Results");
saveAs("text", dir+"Appended_test_files.csv");
print("\nAppended file saved as "+dir+"Appended_test_files.csv");
