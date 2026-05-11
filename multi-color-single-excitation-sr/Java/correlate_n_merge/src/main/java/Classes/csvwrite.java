/* Copyright (C) 2019 Rolf Harkes
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package Classes;

import java.io.File;
import com.opencsv.CSVWriter;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Locale;

public class csvwrite {
    private File file;
    private String[] header;
    private double[][] data; //[row] [column]
    private String numericFormat;
    private String[] numericFormats;
    
    public csvwrite(File file){
    	this.file = file;
        this.numericFormat = "%.4f";
    }
    public csvwrite(File file,String numericFormat){
    	this.file = file;
    	this.numericFormat=numericFormat;
    }
    public void setheader(String[] header) {
    	this.numericFormats = new String[header.length]; 
    	for (int i = 0; i<header.length;i++) {
    		numericFormats[i] = numericFormat;
    	}
    	this.header=header;
    }
    public void setheader(String[] header,String[] numericFormats) {
    	this.header = header;
    	this.numericFormats=numericFormats;
    }
    public void setdata(double[][] data) {
    	this.data=data;
    }
    public void setdata(String colname, double[] d) {
        //find row in the header
        int col = -1;
        for (int i = 0; i < header.length; i++) {
            if (colname.equals(header[i])) {
                col = i;
            }
        }
        setdata(col,d);
    }
    public void setdata(int col, double[] d) {
        //set column
        for (int i=0; i<d.length;i++){
            data[i][col]=d[i]; //for all rows
        }
    }
    public void writeall(){
        try {
            file.createNewFile();
            CSVWriter writer = new CSVWriter(new FileWriter(file));
            
            writer.writeNext(header);
            for (int i=0;i<data.length;i++){
                String[] s = new String[data[0].length];
                for (int j=0;j<data[0].length;j++) {
                    s[j] = String.format(Locale.ROOT, numericFormats[j],data[i][j]);
                }
                writer.writeNext(s,false);
            }
            writer.close();
        } catch (FileNotFoundException ex) {
            
        } catch (IOException ex) {
            
        }
    }
}