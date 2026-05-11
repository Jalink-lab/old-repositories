#include "mex.h"
void subtractMedian(unsigned short *inputData,const mwSize *dimensions,unsigned short *unrankArray,unsigned short histSize,unsigned short window,unsigned short offset){
    unsigned int pixels = dimensions[0]*dimensions[1];
    unsigned int T = dimensions[2];
    unsigned short hist[histSize];
    unsigned short medianPosition = window/2;
    unsigned short tempres[T-window+1];
    unsigned short aux;
    unsigned short median;
    unsigned short removeValue;
    unsigned short addValue;
    for (int p = 0;p<pixels;p++){
        //clear out histogram
        for (int i = 0;i<histSize;i++){hist[i]=0;}
        for (int t = 0; t <= (T - window); t++) { //over all timepoints
            if(t==0){
                for (int t2 = 0; t2 < window; t2++) { //For each frame inside the window
                    hist[inputData[p + pixels*t2]]++; //Add it to the histogram
                }
                short count = 0;
                short j = -1;
                while (count <= medianPosition) //Counting the histogram, until it reaches the median
                {
                    j++;
                    count += hist[j];
                }
                aux = (short) (medianPosition-count+hist[j]+1); //position in the bin. 1 is lowest.
                median = j;
            } else {
                removeValue = inputData[p + pixels*(t-1)];
                addValue = inputData[p + pixels*(t+window-1)];
                hist[removeValue]--; //Removing old pixel
                hist[addValue]++; //Adding new pixel
                if (!(((removeValue > median)
                && (addValue > median))
                || ((removeValue < median)
                && (addValue < median))
                || ((removeValue == median)
                && (addValue == median)))) //Add and remove the same pixel, or pixel from the same side, the median doesn't change
                {
                    short j = median;
                    if ((addValue > median) && (removeValue < median)) //The median goes right
                    {
                        if (hist[median] == aux) //The previous median was the last pixel of its column in the histogram, so it changes
                        {
                            j++;
                            while (hist[j] == 0) //Searching for the next pixel
                            {
                                j++;
                            }
                            median = j;
                            aux = 1; //The median is the first pixel of its column
                        } else {
                            aux++; //The previous median wasn't the last pixel of its column, so it doesn't change, just need to mark its new position
                        }
                    } else if ((removeValue > median) && (addValue < median)) //The median goes left
                    {
                        if (aux == 1) //The previous median was the first pixel of its column in the histogram, so it changes
                        {
                            j--;
                            while (hist[j] == 0) //Searching for the next pixel
                            {
                                j--;
                            }
                            median = j;
                            aux = hist[j]; //The median is the last pixel of its column
                        } else {
                            aux--; //The previous median wasn't the first pixel of its column, so it doesn't change, just need to mark its new position
                        }
                    } else if (addValue == median) //new pixel = last median
                    {
                        if (removeValue < median) //old pixel < last median, the median goes right
                        {
                            aux++; //There is at least one pixel above the last median (the one that was just added), so the median doesn't change, just need to mark its new position
                        }								//else, absolutely nothing changes
                    } else //pixel==median, old pixel = last median
                    {
                        if (addValue > median) //new pixel > last median, the median goes right
                        {
                            if (aux == (hist[median] + 1)) //The previous median was the last pixel of its column, so it changes
                            {
                                j++;
                                while (hist[j] == 0) //Searching for the next pixel
                                {
                                    j++;
                                }
                                median = j;
                                aux = 1; //The median is the first pixel of its column
                            }
                            //else, absolutely nothing changes
                        } else //pixel2<median, new pixel < last median, the median goes left
                        {
                            if (aux == 1) //The previous median was the first pixel of its column in the histogram, so it changes
                            {
                                j--;
                                while (hist[j] == 0) //Searching for the next pixel
                                {
                                    j--;
                                }
                                median = j;
                                aux = hist[j]; //The median is the last pixel of its column
                            } else {
                                aux--; //The previous median wasn't the first pixel of its column, so it doesn't change, just need to mark its new position
                            }
                        }
                    }
                }
            }
            tempres[t] = unrankArray[median];
        } //all timepoints
        // now convert this pixel back from rank to original data and subtract the median
        // this must be done AFTER median calculation. Otherwise we mix rank and original.
        for (int t = 0; t < T; t++) {
            if (t <= medianPosition) {            //Apply first median to frame 0->medianPosition
                inputData[p + pixels*t] = (offset+unrankArray[inputData[p + pixels*t]]) - tempres[0];
            } else if (t<(T - medianPosition)) {  //Apply median from medianPosition back to the current frame 
                inputData[p + pixels*t] = (offset+unrankArray[inputData[p + pixels*t]]) - tempres[t-medianPosition];
            } else {                      //Apply last median to frame (T-medianPosition)->T
                inputData[p + pixels*t] = (offset+unrankArray[inputData[p + pixels*t]]) - tempres[T-window];
            }
        }
    }//all pixels
}
/* The gateway function */
void mexFunction( int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[])
{
    unsigned short *inputData;               /* 1xN input matrix */
    unsigned short *unrankArray;             /* 1xN input matrix */
    const mwSize *dimensions;
    unsigned short histSize;
    unsigned short window;
    unsigned short offset;
    
    /* check for proper number of arguments */
    if(nrhs!=4) {
        mexErrMsgIdAndTxt("MATLAB:cppfeature:invalidNumInputs","Four inputs required.");
    }
    if(nlhs!=0) {
        mexErrMsgIdAndTxt("MATLAB:cppfeature:invalidNumOutputs","No output required.");
    }
    /* make sure the input arguments are Uint16 */
    if( !mxIsUint16(prhs[0]) ) {
        mexErrMsgIdAndTxt("MATLAB:cppfeature:notUint16","Input 1 must be a uint16.");
    }
    if( !mxIsUint16(prhs[1]) ) {
        mexErrMsgIdAndTxt("MATLAB:cppfeature:notUint16","Input 2 must be a uint16.");
    }
    if (mxGetNumberOfDimensions(prhs[0])!=3){
        mexErrMsgIdAndTxt("MATLAB:cppfeature:not3D","Input 1 must be three dimensional.");
    }
        
    /* create a pointer to the real data in the input matrices  */
    inputData = (unsigned short *) mxGetPr(prhs[0]);    
    unrankArray = (unsigned short *) mxGetPr(prhs[1]);
    /* get data from input scalars */
    window = (unsigned short) mxGetScalar(prhs[2]);
    offset = (unsigned short) mxGetScalar(prhs[3]);
    
    /* get information about the data */
    dimensions = mxGetDimensions(prhs[0]);
    histSize = mxGetNumberOfElements(prhs[1]);
    
    /* call the computational routine */
    subtractMedian(inputData,dimensions,unrankArray,histSize,window,offset);
}