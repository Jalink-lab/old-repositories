"""
Extracts lifetimes from the tiff file
"""
import numpy as np


def get_lifetimes(componentdata, labelmap, ertr, tau=None, remove_last_frame=True):
    """
    Extracts lifetimes from the tiff files
    """
    # We want to filter data after total analysis, not during
    # Hence, min_pix and min_int for the ROIs were removed from the function
    # The errors corresponding to min_pix and min_int for the ROIs are commented out
    # Intead we write Mean_init_int and ROI_size to final dataframe

    errors = [ertr.newerror("ROI does not excist"),
              ertr.newerror("ROI smaller than min_pix"),
              ertr.newerror("ROI mean intensity smaller than min_int"),
              ertr.newerror("ROI intensitytrace has one or more zeros")]
    if tau is None:
        tau = [0.6, 3.4]
    if remove_last_frame:
        componentdata = componentdata[:-1]
    n_roi = np.max(labelmap)
    frames = componentdata.shape[0]
    # check roi validity
    #for roi in range(n_roi):
    #    mask = labelmap == (roi + 1)
    #    if np.sum(mask) == 0:
    #        ertr.seterror(roi, errors[0])
    #    else:
    #        if np.sum(mask) < min_pix:
    #            ertr.seterror(roi, errors[1])
    #        intensity = componentdata * mask
    #        mean_pix = np.sum(intensity) / (intensity.shape[0] * np.sum(mask))
    #        if mean_pix < min_int:
    #            ertr.seterror(roi, errors[2])

    intensitytraces = np.empty((n_roi, frames))
    lifetimetraces = np.empty((n_roi, frames))
    ROI_size = np.empty((n_roi)) # make a new array to store ROI sizes in pixels
    for roi in range(n_roi):
        if ertr.haserror(roi):
            continue
        mask = labelmap == (roi + 1)
        ROI_size[roi] = np.sum(mask)
        intensity = componentdata * mask
        # sum in x and y
        intensity = np.sum(intensity, axis=3)
        intensity = np.sum(intensity, axis=2)
        # sum both channels
        intensitytrace = np.sum(intensity.astype(np.float), axis=1)
        # set an error for the trace that has a 0 intensity
        if (intensitytrace == 0).any():
            ertr.seterror(roi, errors[3])
        # Make the lifetimetrace NaN where intensity is 0
        intensitytrace[intensitytrace == 0] = np.inf
        lifetimetrace = (intensity[:, 0] * tau[0] + intensity[:, 1] * tau[1]) / intensitytrace
        intensitytrace = intensitytrace/np.sum(mask)  # store the mean per pixel
        intensitytraces[roi, :] = intensitytrace
        lifetimetraces[roi, :] = lifetimetrace

    return intensitytraces, lifetimetraces, ertr, ROI_size
