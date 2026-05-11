"""
script to test ways for goodness of fit
"""
import numpy as np
from pathlib import Path
from AutomatedCellAnalysis.fit_lifetimes import fit_lifetimes
from matplotlib import pyplot as plt


def _fit_function(x, a, b, c, d):
    return a + b / (1 + np.exp(-c * (x - d)))


## load data
base_path = Path('K:\\SurfDrive\\')
resultpath = Path(base_path, 'Screening_Data_Mutable\\2019\\12\\05\\results')
resultfile = 'B02_tau.csv'
frameinterval = 5
forskendpoint = False
lifetimetraces = np.loadtxt(Path(resultpath, resultfile))

## copy from fit_lifetimes.py
nroi = lifetimetraces.shape[0]
ntime = lifetimetraces.shape[1]

# find the fit-range
fitrange = np.zeros(shape=2, dtype=int)
mean_trace = np.mean(lifetimetraces, axis=0)

d_mean_trace = np.diff(mean_trace)
fitrange[0] = np.argmax(mean_trace[0:int(150 / frameinterval)])  # maximum in the first 150 seconds
fitrange[1] = ntime - 1
if forskendpoint:
    # 3 frames before maximum increase after peak.
    fitrange[1] = fitrange[0] + np.argmax(d_mean_trace[fitrange[0]:]) - 1

xdat = np.arange(0, ntime * frameinterval, frameinterval)
mean_start = np.mean(mean_trace[1:5])

## display
plt.plot(xdat, mean_trace, '-', xdat[fitrange[0]], mean_trace[fitrange[0]], 'x', xdat[fitrange[1]],
         mean_trace[fitrange[1]], 'x')
plt.show()
