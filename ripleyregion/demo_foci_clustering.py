# %load_ext autoreload
# %autoreload 2

import matplotlib
matplotlib.use('tkAgg')
from ripleyregion import Ripleyregion
from ripleyregion import showregion, showripley

# BASIC
rr = Ripleyregion()  # create a square region
for i in range(50):
    rr.addpoint()  # add a random point
f1, a1 = showregion(rr)
f2, a2 = showripley(rr)

# Ellipse (no clustering)
import shapely.affinity
from shapely.geometry import Point

circle = Point(0, 0).buffer(1)  # type(circle)=polygon
ellipse = shapely.affinity.scale(circle, 15, 20)  # type(ellipse)=polygon
rr = Ripleyregion(region=ellipse)
for i in range(50):
    rr.addpoint()  # add a random point
f1, a1 = showregion(rr)
f2, a2 = showripley(rr, dmax=15)

# Ellipse (with clustering)
import random
import shapely.affinity
from shapely.geometry import Point

circle = Point(0, 0).buffer(1)  # type(circle)=polygon
ellipse = shapely.affinity.scale(circle, 15, 20)  # type(ellipse)=polygon
rr = Ripleyregion(region=ellipse)
for i in range(20):
    rr.addpoint()  # add a random point
for i in range(20):
    pt = Point(random.normalvariate(0, 2), random.normalvariate(0, 2))
    rr.addpoint(pt)
f1, a1 = showregion(rr)
f2, a2 = showripley(rr, dmax=15)
