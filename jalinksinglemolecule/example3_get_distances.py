"""
Shows how a ThunderStormFile can get nearest neighbor distances to:
* a point
* another thunderstormfile
* a .roi file
"""
import matplotlib.pyplot as plt
import numpy as np
from roifile import ImagejRoi  # pip install roifile
from jalinksinglemolecule import ThunderStormFile
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
    if dist_to_lam[i]<100:
        plt.plot([xy_a488[i, 0], xy_a647[idx, 0]], [xy_a488[i, 1], xy_a647[idx, 1]], 'k-', alpha=0.5, LineWidth=1)
        plt.plot(xy_a488[i, 0]+x_circ*dist_to_lam[i], xy_a488[i, 1]+y_circ*dist_to_lam[i], 'g-', alpha=0.5)
ax = plt.gca()
ax.set_aspect('equal')
plt.show()
