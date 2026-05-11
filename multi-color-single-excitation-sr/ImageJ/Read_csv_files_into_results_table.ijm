#@ File (label = "Select text file", style = "file") path

text_file = File.openAsString(path);
lines = split(text_file,"\n");
headers = split(lines[0],",");

m=0;
for(j=1;j<lines.length;j++) {
	values = split(lines[j],",");
//		if(j==1) setResult("filename",m,substring(textfile_list[i], 0, lengthOf(textfile_list[i])-12));	//Only print file name at the first occurrance
//		else setResult("filename",m,"");
	for(k=0;k<headers.length;k++) {
		setResult(headers[k],m,parseFloat(values[k]));
	}
	m++;
}
updateResults();
selectWindow("Results");