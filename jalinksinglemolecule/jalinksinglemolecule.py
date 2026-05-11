"""
Class for working with thunderstorm csv files.
"""
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from scipy.spatial import cKDTree as KDTree
from roifile import ImagejRoi  # pip install roifile


def min_sq_distance_point_to_roi(roifile, point):
    """
    :param roifile: must be a polyline
    :param point: the point from which the distance to the line must be calculated
    :return: minimal distance
    """
    # go over all line segments and get the shortest distance to the segment
    # for i in range(1,len(roi))
    min_dist = np.inf
    coords = roifile.coordinates() * 10  # pixelsize
    for crd_idx in range(1, len(coords)):
        min_dist = np.min([min_dist, sq_distance_point_to_line(coords[crd_idx - 1], coords[crd_idx], point)])
    return min_dist


def sq_distance_point_to_line(v0, v1, p):
    """
    :param v0: start of line
    :param v1: end of line
    :param p: point
    :return: smallest distance from point to line
    """
    # squared distance from a point to a line.
    # v0 and v1 define start and finish of the line as 2 elements(x and y)
    # p is the point as a 2 elements (x and y)
    length_squared = (v0[0] - v1[0]) ** 2 + (v0[1] - v1[1]) ** 2
    if length_squared == 0:  # the line is a point
        return (v0[0] - p[0]) ** 2 + (v0[1] - p[1]) ** 2
    t = np.max((0, np.min((1, np.dot(p - v0, v1 - v0) / length_squared))))
    proj = v0 + t * (v1 - v0)
    return (proj[0] - p[0]) ** 2 + (proj[1] - p[1]) ** 2


class ThunderStormFile:
    """A class around a ThunderStorm .csv file"""
    ver = 2.0  # class variable

    def __init__(self, input_path):
        self.path = input_path  # instance variable
        self.data = pd.read_csv(input_path)
        self.N = len(self.data)
        self.kdtree = None

    def __str__(self):
        return "TunderStormFile: " + self.path

    def render(self, pix=20, cmin=0, cmax=5, cmap_name='hot'):
        """
        :param pix: pixelsize
        :param cmin: lowest intensity
        :param cmax: highest intensity
        :param cmap_name: name of the colormap
        :return: h, xedges, yedges, im
        """
        xy = self.getxy()
        xedges = np.arange(0, xy[:, 0].max() + pix, pix)
        yedges = np.arange(0, xy[:, 1].max() + pix, pix)
        cmap = plt.cm.get_cmap(cmap_name)
        h, xedges, yedges, im = plt.hist2d(xy[:, 0], xy[:, 1], bins=[xedges, yedges], cmin=cmin,
                                           cmax=cmax, cmap=cmap)
        ax = plt.gca()
        ax.set_aspect('equal')
        plt.show()
        return h, xedges, yedges, im

    def getxy(self):
        """
        :return: xy-data as numpy array
        """
        return self.data[['x [nm]', 'y [nm]']].to_numpy()

    def make_kdtree(self):
        """
        creates a kdtree in the thunderstormfile
        """
        self.kdtree = KDTree(self.getxy())

    def get_nearest_neighbors(self, other):
        """Get the nearest neighbor distances from self to other"""
        if isinstance(other, ThunderStormFile):
            if other.kdtree is None:
                other.make_kdtree()
            return other.kdtree.query(self.getxy())
        elif isinstance(other, ImagejRoi):
            # must find the distance for each point in self to the roifile in other
            dist = np.zeros(self.N)
            for xy_idx, xy in enumerate(self.getxy()):
                dist[xy_idx] = np.sqrt(min_sq_distance_point_to_roi(other, xy))
            return dist
        else:
            raise "Invalid type " + type(other) + "must be TunderStormFile"

    def isversion(self, version=1):
        """
        :param version: minimum version required
        :return: true or false
        """
        if version <= self.ver:
            return True
        else:
            return False


# This part is so the jalinksinglemolecule.py is runnable by itself. 
# It is ignored when the class is imported from somewhere else.
# Usefull for debugging a
if __name__ == "__main__":
    print("debug")

rootFolder='c://dataff//'
histones = rootFolder+'07-190906+HT1080WT+H3K9Me3A647.csv'
a=ThunderStormFile(histones)
