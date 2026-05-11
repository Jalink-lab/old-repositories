"""
Display RipleyRegions
"""
import numpy as np

from ripleyregion import Ripleyregion
from matplotlib import pyplot as plt


def showarcs(rr: Ripleyregion):
    fig, ax = plt.subplots(1, 1)
    for i in range(rr.arcs.shape[1]):
        ax.plot((0, rr.arcs[0, i]), (0, rr.arcs[1, i]), '-b')
    ax.axis('equal')
    return fig, ax


def showregion(rr: Ripleyregion):
    fig, ax = plt.subplots(1, 1)
    ax.plot(*rr.region.exterior.xy)
    for pt in rr.points:
        ax.plot(pt.x, pt.y, '.')
    ax.axis('equal')
    return fig, ax


def showripley(rr: Ripleyregion, dmax: float = None):
    if rr.ripley is None or rr.distance is None:
        rr.getripleycurve()
    fig, ax = plt.subplots(1, 1)
    if dmax is None:
        idx = len(rr.distance)
    else:
        idx = np.argmax(rr.distance > dmax)
    ax.plot(rr.distance[0:idx], rr.ripley[0:idx])
    ax.set_xlabel('Distance')
    ax.set_ylabel('Ripley L(r)-r')
    return fig, ax
