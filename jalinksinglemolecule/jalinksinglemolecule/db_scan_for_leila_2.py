"""
Demo to show how to do db-scan with thunderstorm csv files
"""
from pathlib import Path
from jalinksinglemolecule import ThunderStormFile
from sklearn.cluster import DBSCAN
import matplotlib.pyplot as plt
import numpy as np

my_csv = Path('C:\\', 'Users', 'l.nahidi', 'Desktop', '1','08-design1+20200709+HAP1+LADsA647.csv')
tsf = ThunderStormFile(my_csv)
xy = tsf.getxy()
db = DBSCAN(eps=50, min_samples=50).fit(xy)
labels = db.labels_
n_clusters = len(set(labels)) - (1 if -1 in labels else 0)
print(f"found {n_clusters} clusters")

# display
unique_labels = set(labels)
colors = [plt.cm.Spectral(each) for each in np.linspace(0, 1, len(unique_labels))]
for k, col in zip(unique_labels, colors):
    if k == -1:
        col = [0, 0, 0, 1]
        markersize = 1
    else:
        markersize = 3
    class_member_mask = (labels == k)
    xy_tmp = xy[class_member_mask]
    plt.plot(xy_tmp[:, 0], xy_tmp[:, 1], 'o', markerfacecolor=tuple(col), markeredgecolor='k',
             markersize=markersize, markeredgewidth=0.0)
    ax = plt.gca()
    ax.set_aspect('equal')
    plt.title(my_csv, fontsize=12)
    plt.suptitle(db)
plt.show()