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
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import com.opencsv.CSVReader;
import java.util.Iterator;
import java.util.List;
/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
/**
 *
 * @author r.harkes
 */
public class csvread {
    private File file;
    private String[] header;
    private double[][] data; //[row] [column]
    private int Nrows;
    private int Ncols;

    public csvread(File name) throws IOException {
        file = name;
        try (CSVReader reader = new CSVReader(new FileReader(file))) {
        	header = getcsvheader(reader);
            Ncols = header.length;
            data = getcsvdata(reader);
            Nrows = data.length;
            reader.close();
        } catch (FileNotFoundException ex) {
            throw ex;
        } catch (IOException ex) {
            throw ex;
        }
    }
    public int getNumberOfColumns() {
    	return Ncols;
    }
    public int getNumberOfRows() {
    	return Nrows;
    }
    public String[] getheader() {
        return header;
    }

    public double[][] getdata() {
        return data;
    }

    public double[] getdata(int row) {
        return data[row];
    }
    
    public double getdata(int row, int col) {
        return data[row][col];
    }

    public double[] getdata(String colname) {
        //find row in the header
        int col = 0;
        for (int i = 0; i < header.length; i++) {
            if (colname.equals(header[i])) {
                col = i;
            }
        }
        //return column
        double[] out = new double[data.length];
        for (int i=0; i<data.length;i++){
            out[i]=data[i][col]; //for all rows
        }
        return out;
    }

    private String[] getcsvheader(CSVReader reader) {
        try {
            String[] head = reader.readNext();
            return head;
        } catch (IOException ex) {
            return null;
        }
    }

    private double[][] getcsvdata(CSVReader reader) {
        try {
            List<String[]> csvdat = reader.readAll();
            Iterator<String[]> itr = csvdat.iterator();
            double[][] out = new double[csvdat.size()][header.length];
            int ct = 0;
            while(itr.hasNext()){ 
                String[] line = itr.next();
                for (int i = 0; i < header.length; i++) {
                    out[ct][i] = Double.valueOf(line[i]);
                }
                ct++;
            }
            return out;
        } catch (IOException ex) {
            return null;
        }
    }
}
