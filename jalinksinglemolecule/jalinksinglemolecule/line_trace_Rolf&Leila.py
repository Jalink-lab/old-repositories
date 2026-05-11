import numpy as np
from jalinksinglemolecule import ThunderStormFile
import matplotlib.pyplot as plt
from line_trace_Rolf import direction2angle, traceline
from roifile import ImagejRoi


lamin_file = '10-200128+HT1080WT+LaminBA532_chromcorr.csv'
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
plt.plot(a[0], a[1], marker='x', color='red', Markersize=5)

# to get the direction
print("What is the second point? Please click")
b = np.asarray(plt.ginput(2))
b = b[0]
print("coordinates are", b, type(b))
plt.plot(b[0], b[1], marker='x', color='green', Markersize=5)

ang = direction2angle(b-a) 
line = traceline(tsf.getxy(), point=a, angle=ang, visualize=False) #
plt.plot(line[:, 0], line[:, 1], '.r', Markersize=5)
plt.show()


roi = ImagejRoi.frompoints(line)
roi.tofile('mytest.roi')

