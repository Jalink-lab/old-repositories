"""
Shows how you can count the number of localizations around a point
"""

import matplotlib.pyplot as plt
import numpy as np
from jalinksinglemolecule import ThunderStormFile

ts_a532 = ThunderStormFile('10-200128+HT1080WT+LaminBA532_chromcorr.csv')
ts_a532.make_kdtree()
pt = [4500, 15600]
r = 200
pts_in_circle = ts_a532.kdtree.query_ball_point(pt, r)  # a ball query requests all points in a circle
print(f"found {len(pts_in_circle)} points in circle")

# display result for verification
ph = np.linspace(0, 2 * np.pi, 360)
xc = pt[0] + r * np.cos(ph)
yc = pt[1] + r * np.sin(ph)
xy = ts_a532.getxy()
plt.plot(xy[:, 0], xy[:, 1], '.', Markersize=0.5)
plt.plot(xc, yc)
ax = plt.gca()
ax.set_aspect('equal')
plt.title(f"found {len(pts_in_circle)} points in circle")
plt.show()
