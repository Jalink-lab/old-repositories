#include "mex.h"

void denseRank(unsigned short *data, long nrElements, unsigned short *unrankArray)
{
    //mexPrintf("number of elements %d\n",nrElements);
    bool doesExist [65536]= {false};
    for (int i=0;i<nrElements;i++){
        doesExist[data[i]]=true;
    }
    short subtract [65536];
    long idx = 0;
    long subtractvalue = 0;
    for (int i=0;i<65536;i++){
        if (doesExist[i]) {
            //mexPrintf("%d exists\n",i);
            subtract[i]=subtractvalue;
            unrankArray[idx] = subtractvalue+idx;
            idx++;
        } else {
            subtractvalue++;
        }
    }
    for (int i=0;i<nrElements;i++){
        data[i] = data[i] -subtract[data[i]];
    }
}


/* The gateway function */
void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray *prhs[])
{
    long nrElements;
    unsigned short *inMatrix;               /* 1xN input matrix */
    unsigned short *outMatrix;              /* output matrix */
    size_t nrows;                   /* size of matrix */
    
    /* check for proper number of arguments */
    if(nrhs!=1) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nrhs","One inputs required.");
    }
    if(nlhs!=1) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:nlhs","One output required.");
    }
    /* make sure the first input argument is scalar */
    if( !mxIsUint16(prhs[0]) ) {
        mexErrMsgIdAndTxt("MyToolbox:arrayProduct:notScalar","Input must be a uint16.");
    }
    
    /* create a pointer to the real data in the input matrix  */
    inMatrix = (unsigned short *) mxGetPr(prhs[0]);
    nrElements = mxGetNumberOfElements(prhs[0]);
    
    /* create the output matrix */
    plhs[0] = mxCreateNumericMatrix(1,65536,mxUINT16_CLASS,mxREAL);
    
    /* get a pointer to the real data in the output matrix */
    outMatrix = (unsigned short *) mxGetPr(plhs[0]);
    
    /* call the computational routine */
    denseRank(inMatrix,nrElements,outMatrix);
}