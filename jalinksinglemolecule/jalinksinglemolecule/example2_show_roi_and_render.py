"""
Shows how you can show the rendering of a ThunderStormFile and a .roi file
"""
import matplotlib.pyplot as plt
from roifile import ImagejRoi  # pip install roifile
from jalinksinglemolecule import ThunderStormFile
roifile = ImagejRoi.fromfile('10-200128+HT1080WT+LaminBA532_chromcorr.roi')
ts_A532 = ThunderStormFile('10-200128+HT1080WT+LaminBA532_chromcorr.csv')
coords = roifile.coordinates()
plt.plot(coords[:,0]*10, coords[:,1]*10)
ts_A532.render()