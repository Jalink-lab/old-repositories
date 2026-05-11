import numpy as np
import math
from jalinksinglemolecule import ThunderStormFile
import matplotlib.pyplot as plt
from line_trace_Rolf import direction2angle, traceline
from pathlib import Path

lamin_file = Path('D:\\', 'Surfdrive', 'Rolf_and_Leila', 'CSV-Archive', '2020', '01', '28 (Leila-H3K9me3WT)',
                  'Results-v2.41', '02-200128+HT1080WT+LaminBA532_chromcorr.csv')


def closestpointtoline(line, pt):
    dline = np.sum((line - pt.T) ** 2, axis=1)
    return np.argmin(dline)


tsf = ThunderStormFile(lamin_file)
xy = tsf.getxy()
plt.plot(xy[:, 0], xy[:, 1], '.b', Markersize=0.5)
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
plt.plot(b[0], b[1], marker='x', color='green', Markersize=10)
ang = direction2angle(b-a)

# trace line
line = traceline(tsf.getxy(), point=a, angle=ang, visualize=False)
plt.plot(line[:, 0], line[:, 1], '.r', Markersize=5)

# where to stop
print("Where to stop? Please click")
c = np.asarray(plt.ginput(2))
c = c[0]
print("coordinates are", c, type(c))
plt.plot(c[0], c[1], marker='x', color='magenta', Markersize=10)

idx = closestpointtoline(line, c)
line = line[:idx]
# redraw figure
plt.clf()
plt.plot(xy[:, 0], xy[:, 1], '.b', Markersize=0.5)
plt.plot(line[:, 0], line[:, 1], '.r', Markersize=5)
plt.show()
ax = plt.gca()
ax.set_aspect('equal')
