"""
Does it all and returns a dataframe that can be passed to displaydata.
"""
import re
from pathlib import Path
from tifffile import TiffFile
import pandas as pd
import numpy as np

from AutomatedCellAnalysis.get_lifetimes import get_lifetimes
from AutomatedCellAnalysis.fit_lifetime_traces import fit_lifetime_traces
from AutomatedCellAnalysis.errortracer import ErrorTracer


def make_dataframe_from_files(labelmap_path, components_path, layout_file, results_path, entered_frameinterval, forskendpoint=False):
    """
    Does it all and returns a dataframe that can be passed to displaydata.
    get_lifetimes  -->  fit_lifetimes  -->
    :return:
    """
    results_path.mkdir(parents=True, exist_ok=True)
    print(f"Starting {labelmap_path}")
    layout = []
    for txt_line in open(layout_file):
        txt_line = txt_line.rstrip()  # remove all spaces and returns at the end of the line
        layout.append(txt_line.split(", "))
        #if this layout file line reads 'PDE1A, D02, G02' there are 2 wells with condition'PDE1A', 
        #namely D02 and G02. content of layout will be: 
        #[['PDE1A', 'D02', 'G02'], ['PDE1B', 'B09', 'E09'], ['PDE1C', 'B10', 'E10'],....]
        #this means that D02 cannot be analyzed separately from G02 unless you change the layout txt file in the folder
    all_data = pd.DataFrame()

    for txt_line in layout:  # each condition
        for i in range(1, len(txt_line)):  # each CONDITION, so, twe two duplicate wells together
            well = txt_line[i]
            print(f"working on well {well} with condition {txt_line[0]}")
            # locate well in components and labelmaps
            componentfile = _locatewell(well, components_path)
            if len(componentfile) == 1:
                componentfile = componentfile[0]
            else:
                print(f"Warning, found {len(componentfile)} componentfiles:")
                for cf in componentfile:
                    print(cf.name)
                print(f"Taking {componentfile[0].name}")
                componentfile = componentfile[0]
            wellnamefiles = _locatewell(well, labelmap_path)  # get all files with the wellname in them
            labelmapfile = None
            for labelmapfile in wellnamefiles:  # find the filename with the word labelmap
                if 'labelmap' in labelmapfile.name:
                    break
            componenttiff = TiffFile(componentfile)
            labelmaptiff = TiffFile(labelmapfile)
            if 'finterval' not in labelmaptiff.shaped_metadata[0]: # if finterval info is not included in tif metadata
                frameinterval = entered_frameinterval                                  # then manually enter the frameinterval value for that experiment
            else:
                frameinterval = labelmaptiff.shaped_metadata[0]['finterval'] #  otherwise the value is taken from the tif metadata
            labelmap = labelmaptiff.asarray()
            ertr = ErrorTracer(np.max(labelmap))  # trace errors for each ROI in the labelmap
            intensitytraces, lifetimetraces, ertr, ROI_size = get_lifetimes(componenttiff.asarray(), labelmap[::2, ::2], ertr)
            np.savetxt(Path(results_path, txt_line[i] + "_tau.csv"), lifetimetraces, delimiter="\t")
            np.savetxt(Path(results_path, txt_line[i] + "_int.csv"), intensitytraces, delimiter="\t")
            [fitvalues, ertr] = fit_lifetime_traces(lifetimetraces, frameinterval, ertr, intensitytraces, ROI_size, forskendpoint=forskendpoint)
            fitvalues['condition'] = txt_line[0]
            fitvalues['frameinterval(s)'] = frameinterval
            fitvalues['well_ID'] = txt_line[i]
            fitvalues = fitvalues.replace([np.inf, -np.inf], np.nan)            
            fitvalues.to_csv(Path(results_path, txt_line[i] + "_fit.csv"))
            ertr.savetxt(Path(results_path, txt_line[i] + "_errors.csv"))
            all_data = pd.concat([all_data, fitvalues])
    all_data.to_csv(Path(results_path, "all_results.csv"))


def _locatewell(find_well, pth):
    foundfiles = []
    for file in pth.iterdir():
        well = re.search('\D\d{1,2}', file.name)  # seach for a letter followed by one or two numbers
        if well:
            well = well.group(0)
            if well == find_well:
                foundfiles.append(file)
    if len(foundfiles) > 0:
        return foundfiles
    else:
        print(f"Did not find {find_well} in {pth}")
