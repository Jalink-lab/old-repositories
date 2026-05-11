#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jun  8 16:33:04 2020

@author: l.nahidiazar&r.harkes
"""
#%matplotlib qt
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path
from line_trace_Rolf import direction2angle, traceline
from roifile import ImagejRoi
from jalinksinglemolecule import ThunderStormFile, get_nearest_neighbors, min_sq_distance_point_to_roi
from Color_check import color_check
import time


# pth = Path('D:\\', 'Surfdrive', 'Rolf_and_Leila', 'CSV-Archive', '2020', '01', '28 (Leila-H3K9me3WT)', 'Results-v2.41')
pth = Path('/Users', 'l.nahidiazar', 'Desktop', 'folder')
print('finds Lamin files to make ROI from files of ' + pth.name)

def closestpointtoline(line, pt):
    dline = np.sum((line - pt.T) ** 2, axis=1) #to get the sum of array elements over a given axis.
    return np.argmin(dline) #Returns the indices of the minimum values along an axis.

    
def LaminLine(pth):   
            # print(A532_collection)
            tsf = ThunderStormFile(x)
            xy = tsf.getxy()
            plt.plot(xy[:, 0], xy[:, 1], '.g', Markersize=0.1)
            ax = plt.gca()
            ax.set_aspect('equal')

            # to get x and y
            print("Where to start? Please click")
            a = np.asarray(plt.ginput(2))
            a = a[0]
            print("coordinates are", a, type(a))
            plt.plot(a[0], a[1], marker='x', color='red', Markersize=10)

            # to get the direction
            print("What is the second point? Please click")
            b = np.asarray(plt.ginput(2))
            b = b[0]
            print("coordinates are", b, type(b))
            plt.plot(b[0], b[1], marker='x', color='red', Markersize=10)
            ang = direction2angle(b-a)
            # trace line
            line = traceline(tsf.getxy(), point=a, angle=ang, visualize=False)
            plt.plot(line[:, 0], line[:, 1], color='red' , Markersize=5)

            # where to stop
            print("Where to stop? Please click")
            c = np.asarray(plt.ginput(2))
            c = c[0]
            print("coordinates are", c, type(c))
            plt.plot(c[0], c[1], marker='x', color='blue', Markersize=10)

            idx = closestpointtoline(line, c)
            line = line[:idx]
            # redraw figure
            plt.clf()
            plt.plot(xy[:, 0], xy[:, 1], '.b', Markersize=0.1)
            plt.plot(line[:, 0], line[:, 1], '.r', Markersize=5)
            plt.show()
            ax = plt.gca()
            ax.set_aspect('equal')
            
            roi = ImagejRoi.frompoints(line)
            roi.tofile(x.with_suffix('.roi'))
            roifile_collection.append(x.with_suffix('.roi'))


plt.clf()
time.sleep(3)
A532_collection = []
roifile_collection = []           
           
for x in pth.iterdir():
        if x.is_file() & (x.suffix == '.csv') & x.name.endswith("532_chromcorr.csv"):
            A532_collection.append(x)
            LaminLine(pth)
            plt.clf()
            
            
if len(A532_collection) is len(roifile_collection):
    print('Mission accomplished')          
            
color_check(pth)            
            
get_nearest_neighbors(self, other)  
# for files in roi and Histone collection   
min_sq_distance_point_to_roi(roifile, point)     
