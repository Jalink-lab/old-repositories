"""
The Experimental Data used in this screen has been collected on 5 seprate days
 *  06-02-2020 (knockdown of PDE 3A and PDE 10 half with caged and half with IsoP/Prop/Forsk)
 *  07-01-2020 (extra IBMX and only cells with IsoP Prop and Forsk)
 *  05-12-2019 (caged cAMP)
 *  07-11-2019 (with IsoP/Prop/Forsk)
 *  02-05-2019 (with IsoP/Prop/Forsk)
 *  02-06-2020 (with IsoP/Prop/Forsk)
 *  02-06-2020 (caged cAMP)
The data is stored in a public Folder called Screening_Data_Notanalyzed
The results will be stored in a new folder called Screening_Data_Analyzed in a folder tree that
mirrors that of the input data.
The data cosists of:
    *intensity timelaps tiff files for each well
    *lifetime tiff files containing two components of the donor lifetime resulting from LASX fit
    *96-well plate layout of that particular experiment
This routine total_analysis calls functions from the folder AutomatedCellAnalysis, in order:
    -save_mean_in_time_of_tiffs which generates average intensity images used for segmentation
    -segment_cells which uses CellPose for deep-learning segmentation
    -make_dataframe_from_files which extracts lifetime data per cell (ROI), along with other info like
    ROI size, ROI mean intensity, possible errors etc. These data are gathered in a pandas dataframe.
"""
from pathlib import Path
from AutomatedCellAnalysis.save_mean_in_time_of_tiffs import save_mean_in_time_of_tiffs
from AutomatedCellAnalysis.segment_cells import segment_cells
from AutomatedCellAnalysis.make_dataframe_from_files import make_dataframe_from_files
from AutomatedCellAnalysis.support_fns import delete_old_results, remember_setting, get_data_replacement_choice, replace_or_backup_old_results
import tkinter as tk
ROOT = tk.Tk()
ROOT.withdraw()
ROOT.attributes('-topmost', True)

#first, find out what files we were analyzing. This is the parent of the folder containing the non-analyzed data
users_basepath=remember_setting('myDataPath', 'C:\\', "Choose parent folder of input data and for placing results data", True)
base_path = Path(users_basepath)
default_frameinterval = 5 #temp solution for first experiment which lacks some metadata
data_replace_choice = get_data_replacement_choice() # 3 choices: deleta All data, Results data or BU results

# set paths to input and output of data and if they have foskolin as endpoint callibration
inpaths = [Path(base_path, 'Screening_Data_Notanalyzed', '2019', '05', '02', 'chemical'), 
           Path(base_path, 'Screening_Data_Notanalyzed', '2019', '11', '07', 'chemical'),
           Path(base_path, 'Screening_Data_Notanalyzed', '2019', '12', '05', 'caged'),
           Path(base_path, 'Screening_Data_Notanalyzed', '2020', '01', '07', 'chemical'),
           Path(base_path, 'Screening_Data_Notanalyzed', '2020', '02', '06', 'chemical'),
           Path(base_path, 'Screening_Data_Notanalyzed', '2020', '02', '06', 'caged')
           ]
# the results will be written in a mirror folder tree that is termed 'Analyzed'
outpaths = [Path(base_path, 'Screening_Data_Analyzed', '2019', '05', '02', 'chemical'),
            Path(base_path, 'Screening_Data_Analyzed', '2019', '11', '07', 'chemical'),
            Path(base_path, 'Screening_Data_Analyzed', '2019', '12', '05', 'caged'),
            Path(base_path, 'Screening_Data_Analyzed', '2020', '01', '07', 'chemical'),
            Path(base_path, 'Screening_Data_Analyzed', '2020', '02', '06', 'chemical'),
            Path(base_path, 'Screening_Data_Analyzed', '2020', '02', '06', 'caged')
            ]
forskendpoints = [True, True, False, True, True, False]

# For each experiment (timelapse) generate the mean of all the timepoints (tiffiles) in the folder
# which will be used later on to segment the cells with DL using CellPose
if data_replace_choice=="A":
    delete_old_results(Path(base_path, 'Screening_Data_Analyzed'), True) #remove all old analysis results
for ct, inpath in enumerate(inpaths):
    print(inpath)
    outpath = outpaths[ct]
    save_mean_in_time_of_tiffs(Path(inpath, 'intensity_data'), Path(outpath, 'intensity_data'))
    # note that save_mean_in_time will skip any files that have already been processed in a previous run 
    # to save time. If you want to redo this step, be sure to delete intermediate results in the 
    # results folder.

# group files per folder and run the segment_cells (this is by far the most lengthy process)
for outpath in outpaths:
    infiles = []
    outfiles = []
    channels = []
    curr_path = Path(outpath, 'intensity_data') #this is the folder with the _mean intensity data
    for file in curr_path.iterdir():
        if file.name[-9:] == '_mean.tif':
            infiles.append(file)
            outfiles.append(Path(curr_path, file.name[:-4] + "_labelmap.tif"))
            channels.append([1, 2])
    segment_cells(infiles, outfiles, channels)
    # note that segment_cells will skip any files that have already been segmented a previous time 
    # to save time. If you want to redo segmentation, be sure to delete intermediate results in the 
    # results folder.

# get dataframe with fit data from segmentation and 2-component fit-data

for ct, outpath in enumerate(outpaths):
    inpath = inpaths[ct]
    layout_file = Path(inpath, 'PlateLayout.txt')
    labelmap_path = Path(outpath, 'intensity_data')
    components_path = Path(inpath, 'two_comp_fit')
    results_path = Path(outpath, 'results')
    replace_or_backup_old_results(results_path, data_replace_choice)
    forskendpoint = forskendpoints[ct]
    make_dataframe_from_files(labelmap_path, components_path, layout_file, results_path, default_frameinterval, forskendpoint=forskendpoint)

# to reload a module:
'''
from importlib import reload
import AutomatedCellAnalysis
reload(AutomatedCellAnalysis.segment_cells)
from AutomatedCellAnalysis.segment_cells import segment_cells
'''