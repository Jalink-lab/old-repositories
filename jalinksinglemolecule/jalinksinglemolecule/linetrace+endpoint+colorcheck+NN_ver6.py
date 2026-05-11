"""
Created on Mon Jun  8 16:33:04 2020

@author: l.nahidiazar&r.harkes
"""

import statistics
import matplotlib.pyplot as plt
from matplotlib import cm
import numpy as np
from roifile import ImagejRoi  # pip install roifile
from jalinksinglemolecule import ThunderStormFile
from pathlib import Path
from line_trace_Rolf import direction2angle, traceline
import matplotlib.gridspec as gridspec

# defining the path for files
#my_pth = Path('D:\\', 'Surfdrive', 'Rolf_and_Leila', 'CSV-Archive', '2020', '01', '28 (Leila-H3K9me3WT)',
#              'Results-v2.41', 'temp')
my_pth = Path('/Users', 'l.nahidiazar', 'Desktop', '1')
print('finds Lamin files to make ROI from files of ' + my_pth.name)


# to stop the automated roi
def closestpointtoline(line, pt):
    """
    finds closest position on line to point
    """
    dline = np.sum((line - pt.T) ** 2, axis=1)  # to get the sum of array elements over a given axis.
    return np.argmin(dline)  # Returns the indices of the minimum values along an axis.


def tellme(s):
    """
    print s and set title
    Parameters
    ----------
    s
    """
    print(s)
    plt.title(s, fontsize=12)
    plt.draw()


# to draw rhe roi and save it as a .roi
def lamin_line(pth):
    """
    Lets the user automatically detect the lamin
    """
    # print(A532_collection)
    plt.clf()
    tsf = ThunderStormFile(pth)
    xy = tsf.getxy()

    k = True
    while k is True:
        plt.plot(xy[:, 0], xy[:, 1], '.g', Markersize=0.1)
        ax = plt.gca()
        ax.set_aspect('equal')
        # to get x and y  
        tellme("Where to start? Please click")
        a = np.asarray(plt.ginput())
        a = a[0]
        print("coordinates are", a, type(a))
        plt.plot(a[0], a[1], marker='x', color='red', Markersize=5)
        plt.draw()

        # to get the direction
        tellme("What is the second point? which direction?")
        b = np.asarray(plt.ginput())
        b = b[0]
        print("coordinates are", b, type(b))
        plt.plot(b[0], b[1], marker='x', color='red', Markersize=5)
        plt.draw()
        ang = direction2angle(b - a)
        # trace line
        line = traceline(tsf.getxy(), point=a, angle=ang, visualize=False)
        plt.plot(line[:, 0], line[:, 1], color='red', Markersize=5)
        plt.draw()

        # where to stop
        tellme("Where to stop? Please click")
        c = np.asarray(plt.ginput())
        c = c[0]
        print("coordinates are", c, type(c))
        plt.plot(c[0], c[1], marker='x', color='blue', Markersize=5)
        plt.draw()

        idx_clp = closestpointtoline(line, c)
        line = line[:idx_clp]
        # redraw figure
        # plt.clf()
        plt.plot(xy[:, 0], xy[:, 1], '.b', Markersize=0.1)
        plt.draw()
        h, = plt.plot(line[:, 0], line[:, 1], '.r', Markersize=5)  # will use h, to remove dots.
        plt.draw()
        my_ax1 = plt.gca()
        my_ax1.set_aspect('equal')

        # give a chance to user to correct ROI.
        tellme('Are you happy with the ROI? Key click for yes, mouse click for no.')
        if plt.waitforbuttonpress():
            tellme('good, the next!')
            k = False
        else:
            tellme('you have a chance to do it again.')
            h.remove()
            plt.draw()
            k = True

        roi = ImagejRoi.frompoints(line)
        roi.tofile(pth.with_suffix('.roi'))
        roifile_collection.append(pth.with_suffix('.roi'))


A532_collection = []
roifile_collection = []

for x in my_pth.iterdir():
    if x.is_file() & (x.suffix == '.csv') & x.name.endswith("532_chromcorr.csv"):
        A532_collection.append(x)
        lamin_line(x)
        plt.close()
        # plt.clf()

# to check if all the rois are made and saved.
if len(A532_collection) is len(roifile_collection):
    print('Mission accomplished!')
    print(roifile_collection)

# to check if all the colors are in the file.
A647_collection = []
# A532_collection = []
A488_collection = []
# roifile_collection = []

for x in my_pth.iterdir():
    if x.is_file() & (x.suffix == '.csv'):
        if x.name.endswith("647.csv"):
            A647_collection.append(x)
        # elif x.name.endswith("532_chromcorr.csv"):
        #     A532_collection.append(x)
        elif x.name.endswith("488_chromcorr.csv"):
            A488_collection.append(x)
    if x.is_file() & (x.suffix == '.roi'):
        roifile_collection.append(x)

A647_collection.sort()
A532_collection.sort()
A488_collection.sort()
roifile_collection.sort()

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
            print(roi_file)
    cell_list.append(cell)
# print(cell_list)


# for files in roi and Histone collection draws and saves the graphs
xedges = np.linspace(0, 1000, 33)  # from 0nm to 1000nm with 32 pixels (33 edges = 32 pixels)
yedges = np.linspace(0, 40, 33)  # from 0nm to 40nm with with 32 pixels

dist_to_lam_all = np.empty([0])
dist_to_his_all = np.empty([0])

for cell in cell_list:
    tsv_lad = ThunderStormFile(cell['lad_csvfile'])
    tsv_his = ThunderStormFile(cell['histone_csvfile'])
    roi_lam = ImagejRoi.fromfile(str(cell['lamin_roifile']))
    dist_to_lam = tsv_lad.get_nearest_neighbors(roi_lam)
    dist_to_his = tsv_lad.get_nearest_neighbors(tsv_his)
    dist_to_his = dist_to_his[0]  # only take distance, not indices

    dist_to_lam_all = np.concatenate((dist_to_lam_all,dist_to_lam))
    dist_to_his_all = np.concatenate((dist_to_his_all,dist_to_his))   
    #to make an avarage.    
    
    # make a single figure
    figsize = (10, 10)
    fig = plt.figure()
    # make the axes
    ax1 = plt.subplot2grid((4, 4), (0, 1), rowspan=3, colspan=3, fig=fig)  # big axis for histogram
    ax2 = plt.subplot2grid((4, 4), (0, 0), rowspan=3, colspan=1, fig=fig)  # left one
    ax3 = plt.subplot2grid((4, 4), (3, 1), rowspan=1, colspan=3, fig=fig)  # bottom one

    # make histogram data to go into the first axes
    xcentres = (xedges[1:] + xedges[:-1]) / 2
    ycentres = (yedges[1:] + yedges[:-1]) / 2
    im, xedges, yedges, h_ = ax1.hist2d(dist_to_lam, dist_to_his, bins=[xedges, yedges])
    plt.colorbar(h_, ax=ax1)
    ax1.get_xaxis().set_ticks([])
    ax1.get_yaxis().set_ticks([])

    # make line to go into the left axes
    ax2.plot(np.nansum(im, axis=0), ycentres)
    ax2.set_ylabel('Distance from Histone Mark (nm)')
    ax2.invert_xaxis()
    ax2.set_ylim(bottom=0, top=40)
    
    # make line to go into bottom axes
    ax3.plot(xcentres, np.nansum(im, axis=1))
    ax3.set_xlabel('Distance from Lamina (nm)')
    ax3.set_xlim(left=0, right=1250)
    

    # set title above the figure
    fig.suptitle(A647_file.name[:-4])

    # save figure
    outpth = cell['lad_csvfile'].with_suffix('.png')
    fig.savefig(outpth)


    # show
    plt.show()
    

# make a figure of all.
figsize = (10, 10)
fig = plt.figure()
# make the axes
ax1 = plt.subplot2grid((4, 4), (0, 1), rowspan=3, colspan=3, fig=fig)  # big axis for histogram
ax2 = plt.subplot2grid((4, 4), (0, 0), rowspan=3, colspan=1, fig=fig)  # left one
ax3 = plt.subplot2grid((4, 4), (3, 1), rowspan=1, colspan=3, fig=fig)  # bottom one

# make histogram data to go into the first axes
xcentres = (xedges[1:] + xedges[:-1]) / 2
ycentres = (yedges[1:] + yedges[:-1]) / 2
im, xedges, yedges, h_ = ax1.hist2d(dist_to_lam_all, dist_to_his_all, bins=[xedges, yedges])
plt.colorbar(h_, ax=ax1)
ax1.get_xaxis().set_ticks([])
ax1.get_yaxis().set_ticks([])


# make line to go into the left axes
ax2.plot(np.nansum(im, axis=0), ycentres)
ax2.set_ylabel('Distance from Histone Mark (nm)')
ax2.invert_xaxis()
ax2.set_ylim(bottom=0, top=40)

# make line to go into bottom axes
ax3.plot(xcentres, np.nansum(im, axis=1))
ax3.set_xlabel('Distance from Lamina (nm)')
ax3.set_xlim(left=0, right=1250)


# set title above the figure
fig.suptitle('the whole')
# save figure
outpth = cell['lad_csvfile'].with_suffix('.png')
fig.savefig(outpth)
# show
plt.show()