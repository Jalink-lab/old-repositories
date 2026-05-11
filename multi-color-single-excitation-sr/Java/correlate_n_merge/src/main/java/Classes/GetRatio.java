package Classes;

import java.util.Arrays;

import org.scijava.log.LogService;
import org.scijava.app.StatusService;

import net.imglib2.IterableInterval;
import net.imglib2.RandomAccessibleInterval;
import net.imglib2.img.Img;
import net.imglib2.type.numeric.RealType;
import net.imglib2.util.RealSum;
import net.imglib2.view.Views;

public final class GetRatio {

    public double[] ratio;
    public double[] intensity;
    public boolean error;
    public String errormsg;

    /**
     *
     * @param <T>
     * @param image1
     * @param image2
     * @param fr
     * @param x
     * @param y
     * @param region
     * @param substractMedian
     * @param log
     */
    public <T extends RealType< T>> GetRatio(Img<T> image1, Img<T> image2, int[] fr, int[] x, int[] y, byte region, boolean substractMedian, LogService log, StatusService statusService) {
        final long[] dims1 = new long[image1.numDimensions()];
        image1.dimensions(dims1);
        final long[] dims2 = new long[image2.numDimensions()];
        image2.dimensions(dims2);
        if (compareArrays(dims1, dims2)) {
            error = false;
        } else {
            error = true;
            errormsg = "image dimensions do not agree";
            return;
        }
        long[] offset = {0, 0, 0};
        long[] dimensions = {dims1[0], dims1[1], 1};
        double[][] medianValues = new double[(int) dims1[2]][2]; //initialized as zeros
        log.info("Start Median");
        if (substractMedian) {
            for (int i = 0; i < dims1[2]; i++) {
                statusService.showStatus(i, (int) dims1[2], "calculating median per frame");
                offset[2] = i;
                RandomAccessibleInterval<T> myROI1 = Views.offsetInterval(image1, offset, dimensions);
                IterableInterval<T> myIterableROI1 = Views.iterable(myROI1);
                medianValues[i][0] = computeMedian(myIterableROI1);
                RandomAccessibleInterval<T> myROI2 = Views.offsetInterval(image2, offset, dimensions);
                IterableInterval<T> myIterableROI2 = Views.iterable(myROI2);
                medianValues[i][1] = computeMedian(myIterableROI2);
            }
        }
        int[] offset2 = {0, 0, 0}; //corner of ROI {x,y,fr}
        int[] dimensions2 = {2 * region + 1, 2 * region + 1, 1}; //size of ROI {x,y,fr}
        this.ratio = new double[x.length];
        this.intensity = new double[x.length];
        Arrays.fill(ratio, Double.NaN);
        Arrays.fill(intensity, Double.NaN);
        double[] averageValues = new double[2];
        log.info("Start Ratio");
        for (int i = 0; i < x.length; i++) {
            if ((i%200)==0){
                statusService.showStatus(i, x.length, "calculating ratio per location");
            }
            offset2[0] = x[i] - region;
            if (offset2[0] < 0) {
                continue;
            }
            if ((offset2[0] + 2 * region + 1) > dims1[0]) {
                continue;
            }
            offset2[1] = y[i] - region;
            if (offset2[1] < 0) {
                continue;
            }
            if ((offset2[1] + 2 * region + 1) > dims1[1]) {
                continue;
            }
            offset2[2] = fr[i] - 1; //0 start instead of 1 start
            RandomAccessibleInterval<T> myROI1 = Views.offsetInterval(image1, toLong(offset2), toLong(dimensions2));
            IterableInterval<T> myIterableROI1 = Views.iterable(myROI1);
            averageValues[0] = computeAverage(myIterableROI1) - medianValues[offset2[2]][0];
            RandomAccessibleInterval<T> myROI2 = Views.offsetInterval(image2, toLong(offset2), toLong(dimensions2));
            IterableInterval<T> myIterableROI2 = Views.iterable(myROI2);
            averageValues[1] = computeAverage(myIterableROI2) - medianValues[offset2[2]][1];
            intensity[i] = averageValues[0] + averageValues[1];
            ratio[i] = averageValues[0] / intensity[i];
        }
        log.info("Finished");
    }

    /**
     * Compute the median intensity for an {@link Iterable}.
     *
     * @param <T>
     * @param input - the input data
     * @return - the average as double
     */
    private < T extends RealType< T>> double computeMedian(final Iterable< T> input) {
        int count = 0;
        for (@SuppressWarnings("unused") final T type : input) {
            ++count;
        }
        double[] data = new double[count];
        count = 0;
        for (final T type : input) {
            data[count] = type.getRealDouble();
            ++count;
        }
        Arrays.sort(data);
        int middle = data.length / 2;
        if (data.length % 2 == 1) {
            return data[middle];
        } else {
            return (data[middle - 1] + data[middle]) / 2.0;
        }
    }

    /**
     * Compute the average intensity for an {@link Iterable}.
     *
     * @param <T>
     * @param input - the input data
     * @return - the average as double
     */
    private < T extends RealType< T>> double computeAverage(final Iterable< T> input) {
        // Count all values using the RealSum class.
        // It prevents numerical instabilities when adding up millions of pixels
        final RealSum realSum = new RealSum();
        long count = 0;

        for (final T type : input) {
            realSum.add(type.getRealDouble());
            ++count;
        }

        return realSum.getSum() / count;
    }

    public long[] toLong(int[] input) {
        long[] output = new long[input.length];
        for (int i = 0; i < input.length; i++) {
            output[i] = (long) input[i];
        }
        return output;
    }

    public static boolean compareArrays(long[] array1, long[] array2) {
        boolean b = true;
        if (array1 != null && array2 != null) {
            if (array1.length != array2.length) {
                b = false;
            } else {
                for (int i = 0; i < array2.length; i++) {
                    if (array2[i] != array1[i]) {
                        b = false;
                        return b;
                    }
                }
            }
        } else {
            b = false;
        }
        return b;
    }
}
