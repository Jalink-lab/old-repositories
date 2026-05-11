"""
Fit the logisticfunction to a lifetimetrace
"""
import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import curve_fit
import pandas as pd


def fit_lifetime_traces(lifetimetraces, frameinterval, ertr, intensitytraces, ROI_size, stabilityrange=0.2, maxerror=0.03, start_diff=0.3,
                        forskendpoint=False, debug=False):
    # Olga changed the start_diff threshhold from 0.1 to 0.3 to not exclude reasonable fits that start a bit higher

    """
    Fit the lifetime traces with a sigmoidal function
    :param start_diff: allowed difference between the start of the fit and the start of the data
    :param debug: if true each graph is plotted
    :param maxerror: maximum error on the decayrate
    :param forskendpoint: True if trace ends with the rise caused by foskolin
    :param stabilityrange: allowed deviation from the mean in the first four frames
    :param ertr: error tracer
    :param lifetimetraces: input data
    :param frameinterval:
    error value is 5-bit.
    - stability
    - nan
    - runtime error in fit
    - hight error on rate
    - fit does not start around the start of the data
    eg 10 is 0-1-0-1-0 in bits so there was a nan and a high error on rate.
    """
    errors = [ertr.newerror("Trace starts outside of the stabilityrange"),
              ertr.newerror("Trace has NaNs"),
              ertr.newerror("Trace gave a runtime error in the fit"),
              ertr.newerror("Trace error on the rate is bigger than maxerror"),
              ertr.newerror("Fit does not start around the start of the data")]
    lifetimetraces_selected = lifetimetraces[ertr.errorfree()]
    nroi = lifetimetraces.shape[0]
    ntime = lifetimetraces.shape[1]

    # find the fit-range
    fitrange = np.zeros(shape=2, dtype=int)
    mean_trace = np.mean(lifetimetraces_selected, axis=0)

    d_mean_trace = np.diff(mean_trace)
    fitrange[0] = np.argmax(mean_trace[0:int(150 / frameinterval)])  # maximum in the first 150 seconds
    fitrange[1] = ntime
    if forskendpoint:
        # 3 frames before maximum increase after peak.
        fitrange[1] = fitrange[0] + np.argmax(d_mean_trace[fitrange[0]:]) - 1
    xdat = np.arange(0, ntime * frameinterval, frameinterval)
    xdat_org = np.arange(0, ntime * frameinterval, frameinterval)
    mean_start = np.mean(mean_trace[1:5])
    # required to filter tracks with abberant starting point (first point on FALCON sometimes fishy)
    columns = ['start(ns)', 'range(ns)', 'breakdown_time(s)', 'midpoint(s)', 'start tau(ns)',
               'e_start', 'e_range', 'e_breakdown_time', 'e_midpoint', 'RMSD', 'MAPE', 'error', 'condition',
               'frameinterval(s)', 'well_ID']
    fitresults = pd.DataFrame(np.nan, index=range(nroi), columns=columns)
    fitresults.fillna(0)
    for trace_id in range(nroi):
        #olga adds ROI mean instensty value, ROI size in pixels and ROI number to each line in the dataframe
        roi_int = intensitytraces[trace_id]
        mean_initint = np.mean(roi_int[1:11]) #takes the mean intensity of the ROI in the first 10 frames excluding the very first
        fitresults.at[trace_id, 'ROI_nr'] = trace_id + 1
        fitresults.at[trace_id, 'Mean_init_int'] = mean_initint
        fitresults.at[trace_id, 'ROI_pix'] = ROI_size[trace_id]
        # error 8 is when there is NaN's in the trace. be aware.
        if ertr.haserror(trace_id) & (ertr.geterror(trace_id) < 8):
            continue
        ydat = lifetimetraces[trace_id]
        # throw away the nan's in x and y
        xdat = xdat_org[ydat != np.nan]
        ydat = ydat[ydat != np.nan]
        start_tau = np.mean(ydat[1:5])  # skip first and take next four values
        if (ydat[1:5] < (mean_start - stabilityrange)).any() or (ydat[1:5] > (mean_start + stabilityrange)).any():
            ertr.seterror(trace_id, errors[0])
        p0 = np.array([3.2, -1, 0.05, np.mean(xdat)])
        bounds = ([0, -3.4, 0, 0], [3.4, 0, 1, np.max(xdat)])  # lower and upper fitting bounds; Olga changed to 3.4 upper limit on 20201028
        xdat_selected = xdat[fitrange[0]:fitrange[1]]
        ydat_selected = ydat[fitrange[0]:fitrange[1]]
        if np.isnan(ydat_selected).any():
            ertr.seterror(trace_id, errors[1])
        if debug:
            plt.figure(1)
            plt.clf()
            plt.plot(xdat, ydat)
            plt.plot(xdat_selected, ydat_selected)
            plt.title(f"ROI : {trace_id} ; error : {ertr.geterror(trace_id)}")
            plt.show()
            plt.pause(1)
        try:
            popt, pcov = curve_fit(_fit_function, xdat_selected, ydat_selected, p0=p0, bounds=bounds)
            perr = np.sqrt(np.diag(pcov))
        except RuntimeError:
            ertr.seterror(trace_id, errors[2])
            fitresults.at[trace_id, 'error'] = ertr.geterror(trace_id)
            continue  # if there is a RuntimeError there is nothing to put into the fitresults
        if perr[2] > maxerror:
            ertr.seterror(trace_id, errors[3])
        if np.abs(popt[0] - ydat_selected[0]) > start_diff:
            ertr.seterror(trace_id, errors[4])
        ydat_fit_selected = _fit_function(xdat_selected, popt[0], popt[1], popt[2], popt[3])
        RMSD = np.sqrt(np.mean((ydat_selected - ydat_fit_selected) ** 2))
        MAPE = 100 * np.mean(np.abs(ydat_selected - ydat_fit_selected) / np.abs(ydat_selected))
        fitresults.at[trace_id, 'start(ns)'] = popt[0]
        fitresults.at[trace_id, 'range(ns)'] = popt[1]
        fitresults.at[trace_id, 'breakdown_time(s)'] = (4 / popt[2])
        fitresults.at[trace_id, 'midpoint(s)'] = popt[3]
        fitresults.at[trace_id, 'start tau(ns)'] = start_tau
        fitresults.at[trace_id, 'e_start'] = perr[0]
        fitresults.at[trace_id, 'e_range'] = perr[1]
        # d/dx 4/x = -4/x^2 ;
        fitresults.at[trace_id, 'e_breakdown_time'] = np.sqrt((-4 / (popt[2] ** 2)) ** 2 * perr[2] ** 2)
        fitresults.at[trace_id, 'e_midpoint'] = perr[3]
        fitresults.at[trace_id, 'RMSD'] = RMSD
        fitresults.at[trace_id, 'MAPE'] = MAPE
        fitresults.at[trace_id, 'error'] = ertr.geterror(trace_id)
        fitresults.at[trace_id, 'ROI_nr'] = trace_id + 1
        if debug:
            plt.figure(1)
            plt.clf()
            plt.plot(xdat, ydat)
            plt.plot(xdat_selected, ydat_selected)
            plt.plot(xdat, _fit_function(xdat, popt[0], popt[1], popt[2], popt[3]))
            plt.title(f"ROI : {trace_id} ; error : {ertr.geterror(trace_id)}")
            plt.show()
            plt.pause(1)

    return fitresults, ertr


def _fit_function(x, a, b, c, d):
    return a + b / (1 + np.exp(-c * (x - d)))
