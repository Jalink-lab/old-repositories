"""
combine a few things in scripts
 *  06-02-2020 (knockdown of PDE 3A and PDE 10 half with caged and half with IsoP/Prop/Forsk)
 *  07-01-2020 (extra IBMX and only cells with IsoP Prop and Forsk)
 *  05-12-2019 (caged cAMP)
 *  07-11-2019 (Chemical)
 *  02-05-2019 (Sravasti, with SiR-DNA, chemical)
"""
import pandas as pd
from pathlib import Path
from AutomatedCellAnalysis.save_mean_in_time_of_tiffs import save_mean_in_time_of_tiffs
from AutomatedCellAnalysis.segment_cells import segment_cells
from AutomatedCellAnalysis.make_dataframe_from_files import make_dataframe_from_files
from AutomatedCellAnalysis.displaydata import displaydata

# set paths to input and output of data and if they have foskolin as endpoint callibration
base_path = Path('C:\\', 'Users\\Bram\\surfdrive\\Shared\\')
inpaths = [Path(base_path, 'Screening_Data_Immutable_small')
           ]
outpaths = [Path(base_path, 'Screening_Data_Mutable')
            ]
forskendpoints = [True, False, True, True, False]

inpaths = [Path(base_path, 'Screening_Data_Immutable_small')]
outpaths = [Path(base_path, 'Screening_Data_Mutable_small')]
forskendpoints = [True]

# take the mean for all the files
for ct, inpath in enumerate(inpaths):
    outpath = outpaths[ct]
    save_mean_in_time_of_tiffs(Path(inpath, 'intensity_data'), Path(outpath, 'intensity_data'))

# group files per folder and run the segment_cells (takes forever)
for outpath in outpaths:
    infiles = []
    outfiles = []
    channels = []
    curr_path = Path(outpath, 'intensity_data')
    for file in curr_path.iterdir():
        if file.name[-9:] == '_mean.tif':
            infiles.append(file)
            outfiles.append(Path(curr_path, file.name[:-4] + "_labelmap.tif"))
            channels.append([1, 2])
    segment_cells(infiles, outfiles, channels)

# get dataframe with fit data from segmentation and 2-component fit-data
for ct, outpath in enumerate(outpaths):
    inpath = inpaths[ct]
    layout_file = Path(inpath, 'screenLayout.txt')
    labelmap_path = Path(outpath, 'intensity_data')
    components_path = Path(inpath, 'two_comp_fit')
    results_path = Path(outpath, 'results')
    forskendpoint = forskendpoints[ct]
    make_dataframe_from_files(labelmap_path, components_path, layout_file, results_path, forskendpoint=forskendpoint)

# display the first one
results_path = Path(outpaths[0], 'results')
all_data = pd.read_csv(Path(results_path, "all_results.csv"))
selected_data = all_data[all_data['error'] == 0]
fig, ax = displaydata(selected_data, "breakdown_time(s)")
fig.show()
# to reload a module:
'''
from importlib import reload
import AutomatedCellAnalysis
reload(AutomatedCellAnalysis.segment_cells)
from AutomatedCellAnalysis.segment_cells import segment_cells
'''