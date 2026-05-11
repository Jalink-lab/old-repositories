#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jun  8 16:33:04 2020

@author: l.nahidiazar&r.harkes
"""
from pathlib import Path
from line_trace_Rolf import direction2angle, traceline
import time
import matplotlib.pyplot as plt
import numpy as np
from roifile import ImagejRoi  # pip install roifile
from jalinksinglemolecule import ThunderStormFile

# defining the path for files
my_pth = Path('D:\\', 'Surfdrive', 'Rolf_and_Leila', 'CSV-Archive',
              '2020', '01', '28 (Leila-H3K9me3WT)', 'Results-v2.41')
# pth = Path('/Users', 'l.nahidiazar', 'Desktop', '1')
print('finds Lamin files to make ROI from files of ' + my_pth.name)


# to stop the automated roi
def closestpointtoline(line, pt):
    """
    finds closest position on line to point
    """
    dline = np.sum((line - pt.T) ** 2, axis=1)  # to get the sum of array elements over a given axis.
    return np.argmin(dline)  # Returns the indices of the minimum values along an axis.


# to draw rhe roi and save it as a .roi
def lamin_line(pth):
    """
    Lets the user automatically detect the lamin
    """
    # print(A532_collection)
    tsf = ThunderStormFile(pth)
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
    ang = direction2angle(b - a)
    # trace line
    line = traceline(tsf.getxy(), point=a, angle=ang, visualize=False)
    plt.plot(line[:, 0], line[:, 1], color='red', Markersize=5)

    # where to stop
    print("Where to stop? Please click")
    c = np.asarray(plt.ginput(2))
    c = c[0]
    print("coordinates sare", c, type(c))
    plt.plot(c[0], c[1], marker='x', color='blue', Markersize=10)

    idx_clp = closestpointtoline(line, c)
    line = line[:idx_clp]
    # redraw figure
    plt.clf()
    plt.plot(xy[:, 0], xy[:, 1], '.b', Markersize=0.1)
    plt.plot(line[:, 0], line[:, 1], '.r', Markersize=5)
    plt.show()
    my_ax1 = plt.gca()
    my_ax1.set_aspect('equal')

    roi = ImagejRoi.frompoints(line)
    roi.tofile(pth.with_suffix('.roi'))
    roifile_collection.append(pth.with_suffix('.roi'))


plt.clf()
time.sleep(3)
A532_collection = []
roifile_collection = []

for x in my_pth.iterdir():
    if x.is_file() & (x.suffix == '.csv') & x.name.endswith("532_chromcorr.csv"):
        A532_collection.append(x)
        lamin_line(x)
        plt.clf()

# to check if all the rois are made and saved.
if len(A532_collection) is len(roifile_collection):
    print('Mission accomplished')
    print(roifile_collection)

# to check if all the colors are in the file.
A647_collection = []
A532_collection = []
A488_collection = []
roifile_collection = []

for x in my_pth.iterdir():
    if x.is_file() & (x.suffix == '.csv'):
        if x.name.endswith("647.csv"):
            A647_collection.append(x)
        elif x.name.endswith("532_chromcorr.csv"):
            A532_collection.append(x)
        elif x.name.endswith("488_chromcorr.csv"):
            A488_collection.append(x)
        if x.is_file() & (x.suffix == '.roi'):
            roifile_collection.append(x)

A647_collection.sort()
A532_collection.sort()
A488_collection.sort()

# checks if every image has all the corresponding colors.
cell_list = []  # list with all the individual cell-dictionaries
for A647_file in A647_collection:

    # makes a cell dictionary with the files that belong to one cell
    cell = {'histone_csvfile': A647_file,
            'lad_csvfile': None,
            'lamin_csvfile': None,
            'lamin_roifile': None}

    file_no = A647_file.name[:5]  # need to match this
    print("matching " + file_no)
    for A532_file in A532_collection:
        if file_no in A532_file.name:
            cell['lamin_csvfile'] = A532_file
    for A488_file in A488_collection:
        if file_no in A488_file.name:
            cell['lad_csvfile'] = A488_file
    for roi_file in roifile_collection:
        if file_no in roi_file.name:
            cell['lamin_roifile'] = roi_file
    cell_list.append(cell)
print(cell_list)

# for files in roi and Histone collection
xedges = np.linspace(0, 1000, 33)  # from 0nm to 1000nm with 32 pixels (33 edges = 32 pixels)
yedges = np.linspace(0, 40, 33)  # from 0nm to 40nm with with 32 pixels
for cell in cell_list:
    tsv_lad = ThunderStormFile(cell['lad_csvfile'])
    tsv_his = ThunderStormFile(cell['histone_csvfile'])
    roi_lam = ImagejRoi.fromfile(cell['lamin_roifile'])

    nn_lad_to_histone = tsv_lad.get_nearest_neighbors(roi_lam)  # will be on x
    nn_lad_to_histone = nn_lad_to_histone[0]  # will be on y
    nn_lad_to_lamin = nn_lad_to_histone[0]  # only need the distances, not the indices

    h, xedges, yedges, im = plt.hist2d(nn_lad_to_lamin, nn_lad_to_histone, bins=[xedges, yedges])
    plt.show()

# load csvs and roi
ts_a647 = ThunderStormFile('10-200128+HT1080WT+H3K9me3A647.csv')
ts_a488 = ThunderStormFile('10-200128+HT1080WT+LADsA488_chromcorr.csv')
ts_a532 = ThunderStormFile('10-200128+HT1080WT+LaminBA532_chromcorr.csv')
roi_a532 = ImagejRoi.fromfile('10-200128+HT1080WT+LaminBA532_chromcorr.roi')

# find nearest neighbor from point [400,400] to ts_647
ts_a647.make_kdtree()
NN = ts_a647.kdtree.query(np.array([400, 400]))
print("Distance to point {1} is {0}nm.".format(NN[0], NN[1]))

# find nearest neighbors from ts_a488 to ts_647
nearest_neighbors = ts_a488.get_nearest_neighbors(ts_a647)
dist_to_hist = nearest_neighbors[0]
hist_indices = nearest_neighbors[1]
print("Found {0} nearest neighbor distances.".format(len(dist_to_hist)))

# find distance from ts_a488 to roi
dist_to_lam = ts_a488.get_nearest_neighbors(roi_a532)
print(dist_to_lam)
# verify result
xy_a488 = ts_a488.getxy()
xy_a647 = ts_a647.getxy()
coords = roi_a532.coordinates()
plt.plot(xy_a488[:, 0], xy_a488[:, 1], '.b', markersize=1)
plt.plot(xy_a647[:, 0], xy_a647[:, 1], '.r', markersize=1)
plt.plot(coords[:, 0] * 10, coords[:, 1] * 10)

x_circ = np.cos(np.linspace(0, 2 * np.pi, 100))
y_circ = np.sin(np.linspace(0, 2 * np.pi, 100))
for i, idx in enumerate(hist_indices):
    if dist_to_lam[i] < 100:
        plt.plot([xy_a488[i, 0], xy_a647[idx, 0]], [xy_a488[i, 1], xy_a647[idx, 1]], 'k-', alpha=0.5, LineWidth=1)
        plt.plot(xy_a488[i, 0] + x_circ * dist_to_lam[i], xy_a488[i, 1] + y_circ * dist_to_lam[i], 'g-', alpha=0.5)
my_ax = plt.gca()
my_ax.set_aspect('equal')
plt.show()
