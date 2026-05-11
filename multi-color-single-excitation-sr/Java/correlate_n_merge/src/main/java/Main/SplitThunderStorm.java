/* IntensityFraction
In 2017 Rolf Harkes and Bram van den Broek, Netherlands Cancer Institute, 
implemented the T.S.Huang algorithm in a maven .jar for easy deployment in Fiji (ImageJ2)
The data is read to a single array and each pixel is processed in parallel. 
The filter is intended for pre-processing of single molecule localization data.

Used articles:
T.S.Huang et al. 1979 - Original algorithm for median calculation

This software is released under the GPL v3. You may copy, distribute and modify 
the software as long as you track changes/dates in source files. Any 
modifications to or software including (via compiler) GPL-licensed code 
must also be made available under the GPL along with build & install instructions.
https://www.gnu.org/licenses/gpl-3.0.en.html

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
package Main;

import java.io.File;
import java.io.IOException;

import org.scijava.app.StatusService;
import org.scijava.command.Command;
import org.scijava.command.Previewable;
import org.scijava.log.LogService;
import org.scijava.plugin.Parameter;
import org.scijava.plugin.Plugin;

import Classes.*;
import net.imagej.ImageJ;

/**
 * Subtracts the temporal median
 */
@Plugin(type = Command.class, headless = true,
        menuPath = "Plugins>NKI>Split_Thunderstorm")
public class SplitThunderStorm implements Command, Previewable {

    @Parameter
    private LogService log;

    @Parameter
    private StatusService statusService;

    @Parameter(label = "Input CSV-file", description = "Thunderstorm csv")
    private File csvfile_in1;
    
    @Parameter(label = "Input ratio-file", description = "From plugin")
    private File csvfile_in2;
    
    @Parameter(label = "CSV-file1", description = "Thunderstorm csv")
    private File csvfile_out1;
    
    @Parameter(label = "CSV-file2", description = "Thunderstorm csv")
    private File csvfile_out2;
    
    @Parameter(label = "Min Region 1", description = "Minimum value to qualify for CSV 1")
    private double Min_R1;
    @Parameter(label = "Max Region 1", description = "Maximum value to qualify for CSV 1")
    private double Max_R1;
    @Parameter(label = "Min Region 2", description = "Minimum value to qualify for CSV 2")
    private double Min_R2;
    @Parameter(label = "Max Region 2", description = "Maximum value to qualify for CSV 2")
    private double Max_R2;
    
    public static void main(final String... args) throws Exception {
    	final ImageJ ij = new ImageJ();
        ij.ui().showUI();
    }

    @Override
    public void run() {
    	csvread csvReader1=null;
    	csvread csvReader2=null;
		try {
			csvReader1 = new csvread(csvfile_in1);
	    	csvReader2 = new csvread(csvfile_in2);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
    	csvwrite csvWriter1 = new csvwrite(csvfile_out1);
    	csvwrite csvWriter2 = new csvwrite(csvfile_out2);
    	//check input
    	if (csvReader1.getNumberOfRows()==csvReader2.getNumberOfRows()) {
    		log.debug("Nr of rows in csv files match");
    	}else {
    		log.info("csv1 Rows = "+csvReader1.getNumberOfRows());
    		log.info("csv2 Rows = "+csvReader2.getNumberOfRows());
    		log.error("Nr of rows in csv files do not match");
    	}
    	//copy header
    	String[]  header = csvReader1.getheader();
    	csvWriter1.setheader(header);
    	csvWriter2.setheader(header);
    	//check ratios
    	double ratio[] =  csvReader2.getdata("Ratio");
    	int id[] = new int[ratio.length];
    	int lengthCsv1 = 0;
    	int lengthCsv2 = 0;
    	for (int i=0;i<ratio.length;i++) {
    		if (ratio[i]>Min_R1&&ratio[i]<Max_R1) {
    			id[i]=1;
    			lengthCsv1++;
    		}else if ((ratio[i]>Min_R2&&ratio[i]<Max_R2) ) {
    			id[i]=2;
    			lengthCsv2++;
    		}
    	}
    	//get data in
    	double dataIn[][] = csvReader1.getdata();
    	//allocate space for data out
    	double dataOut1[][] = new double[lengthCsv1][header.length];
    	log.info("length csv1 = "+ lengthCsv1);
    	log.info("length csv2 = "+ lengthCsv2);    	
    	double dataOut2[][] = new double[lengthCsv2][header.length];
    	int idx1 = 0;
    	int idx2 = 0;
    	for (int i=0;i<id.length;i++) {
    		if (id[i]==1) {
    			for (int j=0;j<header.length;j++) {
    				dataOut1[idx1][j]=dataIn[i][j];
    			}
				idx1++;
    		}else if (id[i]==2) {
    			for (int j=0;j<header.length;j++) {
    				dataOut2[idx2][j]=dataIn[i][j];
    			}
				idx2++;
    		}
    	}
    	csvWriter1.setdata(dataOut1);
    	csvWriter1.writeall();
    	csvWriter2.setdata(dataOut2);
    	csvWriter2.writeall();
    }

    @Override
    public void cancel() {
        log.debug("Cancelled");
    }

    @Override
    public void preview() {
        log.debug("previews median");
    }

}