"""
Created on Sat Jun  6 04:21:44 2020

@author: l.nahidiazar
Match .csv files together
"""
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path
from line_trace_Rolf import direction2angle, traceline
from roifile import ImagejRoi
from jalinksinglemolecule import ThunderStormFile

pth = Path('D:\\', 'Surfdrive', 'Rolf_and_Leila', 'CSV-Archive', '2020', '01', '28 (Leila-H3K9me3WT)', 'Results-v2.41')
# pth = Path('/Users', 'l.nahidiazar', 'Desktop', 'folder')
print('finds Lamin files to make ROI from files of ' + pth.name)


def LaminLine():
    A532_collection = []
    roifile_collection = []

    for x in pth.iterdir():
        if x.is_file() & (x.suffix == '.csv') & x.name.endswith("532_chromcorr.csv"):
            A532_collection.append(x)
            print(A532_collection)
            tsf = ThunderStormFile(x)
            xy = tsf.getxy()
            plt.plot(xy[:, 0], xy[:, 1], '.', color='blue', Markersize=0.5)
            ax = plt.gca()
            ax.set_aspect('equal')

            # to get x and y
            print("Where to start? Please click")
            a = np.asarray(plt.ginput(2))
            a = a[0]
            print("coordinates are", a, type(a))
            plt.plot(a[0], a[1], marker='x', color='red', Markersize=5)

            # to get the direction
            print("What is the second point? Please click")
            b = np.asarray(plt.ginput(2))
            b = b[0]
            print("coordinates are", b, type(b))
            plt.plot(b[0], b[1], marker='x', color='green', Markersize=5)

            ang = direction2angle(b - a)
            line = traceline(tsf.getxy(), point=a, angle=ang, visualize=False)  #
            plt.plot(line[:, 0], line[:, 1], '.r', Markersize=5)
            plt.show()

            roi = ImagejRoi.frompoints(line)
            roi.tofile(x - 'csv' + 'roi')
            roifile_collection.append(x)

            # if len(roifile_collection) is len(A532_collection):
            #     print('done')


LaminLine()
