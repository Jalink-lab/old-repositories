import numpy as np
from jalinksinglemolecule import ThunderStormFile
import matplotlib.pyplot as plt
from scipy.spatial import cKDTree as KDTree

def traceline(xy, point, angle, n=20, phi=(np.pi / 8), dx=250, r=100, s=10, visualize=True):
    """ Traces a line in a set of points
    Requires several input parameters. The startpoint `point` and the intitial direction `angle` are required.
    The other parameters are optional and depend on the expected shape of the line. The process can be visualized by
    setting `visualize` to True.

    Parameters
    ----------
    xy : ndarray
    point : ndarray
    angle : float
    n : int
    phi : float
    dx : float
        distance to next point on the line
    r : float
        search radius for localizations
    s : int
        stopping criterium
    visualize : bool

    Returns
    -------
    line : ndarray
        a list of the xy-values of the line
    """
    line = np.array([point])
    kdtree = KDTree(xy)
    max_found = s+1
    while max_found > s:
        circpts = __gen_circle(point=point, angle=angle, dx=dx, n=n, phi=phi)
        n_pts = np.zeros(n, dtype=int)
        for i in range(n): # go over all points
            n_pts[i] = len(kdtree.query_ball_point(circpts[i, :], r))
        max_idx = np.argmax(n_pts)
        max_found = n_pts[max_idx]
        if visualize:
            plt.plot(xy[:, 0], xy[:, 1], '.b', Markersize=0.5)
            plt.plot(line[:, 0], line[:, 1], '.r', Markersize=5)
            plt.plot(circpts[:, 0], circpts[:, 1], '.g')
            plt.plot(circpts[max_idx, 0], circpts[max_idx, 1], '.k')
            plt.arrow(point[0], point[1], np.cos(angle) * 1000, np.sin(angle) * 1000,
                      length_includes_head=True, width=3, head_width=100)
            plt.title(f"found {max_found} points")
            ax = plt.gca()
            ax.set_aspect('equal')
            plt.show()
        line = np.concatenate([line, np.array([circpts[max_idx, :]])])
        angle = direction2angle(circpts[max_idx, :]-point)
        point = circpts[max_idx, :]
    return line

def direction2angle(direction):
    return np.arctan2(direction[1], direction[0])

def __gen_circle(point, angle, dx, n=10, phi=(np.pi / 4)):
    ph = np.linspace(angle - phi / 2, angle + phi / 2, n)
    xy = np.array([point[0] + dx * np.cos(ph), point[1] + dx * np.sin(ph)]).T
    return xy

def __example():
    lamin_file = 'C:\\Users\\Rolf\\gitlabReps\\jalinksinglemolecule\\10-200128+HT1080WT+LaminBA532_chromcorr.csv'
    pt = np.array([4500, 15600])  # x y
    direction = np.array([1000, 300])  # dx dy
    ang = direction2angle(direction)
    tsf = ThunderStormFile(lamin_file)
    line = traceline(tsf.getxy(), point=pt, angle=ang, visualize=False)

    # display
    xy = tsf.getxy()
    plt.plot(xy[:, 0], xy[:, 1], '.b', Markersize=0.5)
    plt.plot(line[:, 0], line[:, 1], '.r', Markersize=5)
    ax = plt.gca()
    ax.set_aspect('equal')
    plt.show()
