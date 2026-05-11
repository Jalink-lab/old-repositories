"""
Shows how to make a 2D histogram from distance data
"""
import matplotlib.pyplot as plt
import numpy as np
from roifile import ImagejRoi  # pip install roifile
from jalinksinglemolecule import ThunderStormFile

# load csvs and roi
histones = ThunderStormFile('10-200128+HT1080WT+H3K9me3A647.csv')
lads = ThunderStormFile('10-200128+HT1080WT+LADsA488_chromcorr.csv')
lamin = ImagejRoi.fromfile('10-200128+HT1080WT+LaminBA532_chromcorr.roi')

nn_lad_to_histone = lads.get_nearest_neighbors(histones)  # will be on y
nn_lad_to_histone = nn_lad_to_histone[0]  # only need the distances, not the indices
nn_lad_to_lamin = lads.get_nearest_neighbors(lamin)  # will be on x

xedges = np.linspace(0, 1000, 33)  # from 0nm to 1000nm with 32 pixels (33 edges = 32 pixels)
yedges = np.linspace(0, 40, 33)  # from 0nm to 40nm with with 32 pixels

# following is a copy from line 69 in jalinksinglemolecule.py
h, xedges, yedges, im = plt.hist2d(nn_lad_to_lamin, nn_lad_to_histone, bins=[xedges, yedges])
plt.show()
