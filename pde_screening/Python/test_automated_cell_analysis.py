"""
test automated cell analysis
"""
from automated_cell_analysis import segment_cells, get_lifetimes, fit_lifetimes, displaydata
from pathlib import Path
import matplotlib.pyplot as plt

base_path = Path('E:\\', 'Surfdrive')
intensityfilepath = Path(base_path, 'Screening_Data', 'PDE_Screen_Caged - E03_segmentation.tif')
labelmap, frameinterval = segment_cells([intensityfilepath], gpu=False)
labelmap = labelmap[0:512:2, 0:512:2]  # the labelmap must be binned for the next step
lifetimefilepath = Path('G:\\', 'SurfDrive', 'Screening_Data', 'E03.tif')
I, tau = get_lifetimes(lifetimefilepath, labelmap)
fitvalues = fit_lifetimes(tau, frameinterval)
fitvalues['condition'] = 'PDE_bla'

displaydata(fitvalues)
plt.show()
