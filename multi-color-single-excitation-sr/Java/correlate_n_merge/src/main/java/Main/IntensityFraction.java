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
package Main; 

import Classes.csvread;
import Classes.GetRatio;
import Classes.csvwrite;
import java.io.File;
import java.io.IOException;

import net.imagej.ImageJ;

import net.imglib2.img.Img;
import net.imglib2.type.numeric.RealType;

import org.scijava.app.StatusService;
import org.scijava.command.Command;
import org.scijava.command.Previewable;
import org.scijava.log.LogService;
import org.scijava.plugin.Parameter;
import org.scijava.plugin.Plugin;

/**
 * Calculates the ratio of two regions in an image
 * @param <T>
 */
@Plugin(type = Command.class, headless = true,
        menuPath = "Plugins>NKI>Intensity_Fraction")
public class IntensityFraction<T extends RealType< T >> implements Command, Previewable {

    @Parameter
    private LogService log;

    @Parameter
    private StatusService statusService;

    @Parameter(label = "Select image 1", description = "the image 1 field")
    private Img<T> image1;
    
    @Parameter(label = "Select image 2", description = "the image 2 field")
    private Img<T> image2;

    @Parameter(label = "CSV-file in", description = "Thunderstorm csv")
    private File csvfile_in;
    
    @Parameter(label = "CSV-file out", description = "Ratio csv")
    private File csvfile_out;
    
    @Parameter(label = "Region", description = "Size will be 2*region+1")
    private byte region;
    
    @Parameter(label = "Pixelsize (nm)", description = "Size of a pixel to convert the values in the .csv")
	private double pixelSize;
    
    @Parameter(label = "Subtract Median", description = "Should the median of the frame be subtracted from the regions")
	private boolean subtractMedian;
    
    public static void main(final String... args) throws Exception {
        // create the ImageJ application context with all available services
        final ImageJ ij = new ImageJ();
        ij.ui().showUI();
    }
    
    @Override
    public void run() {
        try {
            csvread CsvReader = new csvread(csvfile_in);
            int[] fr = toInt(CsvReader.getdata("frame"));
            int[] x = roundDouble(CsvReader.getdata("x [nm]"),pixelSize);
            int[] y = roundDouble(CsvReader.getdata("y [nm]"),pixelSize);
            GetRatio Ratio = new GetRatio(image1,image2,fr,x,y,region,subtractMedian,log,statusService);
            if (Ratio.error) {log.error(Ratio.errormsg);return;}
            csvwrite CsvWriter = new csvwrite(csvfile_out);
            String[] header = {"id","Ratio","Intensity"};
            CsvWriter.setheader(header);
            double[][] data = new double[x.length][3];
            CsvWriter.setdata(data);
            double[] id = new double[x.length];
            for (int i=0;i<x.length;i++) {
                    id[i] = i+1;
            }
            CsvWriter.setdata("id",id);
            CsvWriter.setdata("Ratio",Ratio.ratio);
            CsvWriter.setdata("Intensity",Ratio.intensity);
            CsvWriter.writeall();
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }

    @Override
    public void cancel() {
        log.debug("Cancelled");
    }

    @Override
    public void preview() {
        log.debug("previews Intensity Fraction");
    }
    
    private static int[] toInt(double[] input) {
        if (input == null)
        {
            return null; 
        }
        int[] output = new int[input.length];
        for (int i = 0; i < input.length; i++)
        {
            output[i] = (int) input[i];
        }
        return output;
    }
    
	private static int[] roundDouble(double[] array1,double pixelSize) {
	    int[] out = new int[array1.length];
	    for (int i=0;i<array1.length;i++){
	        out[i] = (int) Math.round(array1[i]/pixelSize);
	    }
	    return out;
	}
}