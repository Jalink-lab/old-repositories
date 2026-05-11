#@ File    (label = "Input CSV file", style = "file") inputFile
#@ File    (label = "Output CSV file", style = "file") outputFile

/* It can be difficult to get the data from the ThunderSTORM table for futher processing.
 *  CSVReader and CSVWriter give a more flexible and direct way of loading csv data.
 *  These libraries can be imported in the script the same way as ImageJ in the previous example.
 *  
 *  The code below is a bit complex. Try to go over the lines and read the comments
 */
 
import com.opencsv.CSVReader 
import com.opencsv.CSVWriter

//read all data and put 'x [nm]' and 'y [nm]'] in a variable called data
String[] headerValues = ['x [nm]','y [nm]']
reader = new CSVReader(new FileReader(inputFile)) // make a new CSVReader that reads the imput file
List<String[]> records = reader.readAll()         // read everything at once and put it in a variable caled records. This is a list that has an array of Strings.
reader.close()
N = reader.getLinesRead()-1 //single line header so the number of rows we want in the data is the number of lines - 1
data = new double[N][headerValues.size()] //we make a new 2 dimensional array. First dimension is N, the number of rows, the second is the number of columns we want to have

Iterator<String[]> iterator = records.iterator() //we want to iterate through the list that was read in line 17 so we change from List to Iterator

//read header and search for requested values
String[] record = iterator.next(); //the first line is the header, it is now stored as record (note the difference between records and record)
idx = new int[headerValues.size()] //we want to know what columns corresponds to our headervalues
for (int j = 0;j<headerValues.size();j++){
	idx[j] = -1 //default value, should be overwritten in the next loop
	for (int i = 0;i<record.size();i++){
		if (record[i]==headerValues[j]){ //did we find the right header value?
			idx[j]=i
		}
	}
	if (idx[j]==-1){ //if we didnt find the header value we throw a new Exception
		throw new Exception("The header value "+headerValues[j]+" was not found")
	}
}
//put data 
for (int i = 0;i<N;i++){
	record = iterator.next();
	for (int j =0;j<headerValues.size();j++){
		data[i][j] = record[idx[j]].toDouble() //convert it to a number
	}
}

//save the x-y data
writer = new CSVWriter(new FileWriter(outputFile),(char)'\t') //make it tab seperated
String[] line = ['x [nm]','y [nm]']
writer.writeNext(line)
for (int i = 0;i<N;i++){
	line[0] = data[i][0].toString()
	line[1] = data[i][1].toString()
	writer.writeNext(line,false) //do not apply quotes to numbers
}
writer.close()

// exercise 1: For each point, calculate the distance from the origin <0,0> and store it as the third column. 
// exercise 2: Rotate the points 20 degrees to the left. 
//   hint: use a rotation matrix. xnew= x*cos(phi) - y*sin(phi) ; ynew = x*sin(phi) + y*cos(phi)
//   hint: Sine of 10 degrees is calculated using Math.sin(Math.toRadians(10)) see below
println Math.sin(Math.toRadians(10))