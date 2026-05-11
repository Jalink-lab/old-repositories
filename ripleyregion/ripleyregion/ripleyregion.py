import random

import numpy as np
from shapely.geometry import Polygon, Point
import logging
from tqdm import tqdm


def _getarcs(arcs: int) -> np.ndarray:
    ph = np.linspace(0, 2 * np.pi, arcs)
    return np.vstack((np.cos(ph), np.sin(ph)))


def _get_random_point_in_polygon(poly: Polygon) -> Point:
    minx, miny, maxx, maxy = poly.bounds
    while True:
        p = Point(random.uniform(minx, maxx), random.uniform(miny, maxy))
        if poly.contains(p):
            return p


def _get_point_coordinates(points: list[Point]) -> np.ndarray:
    coords = np.zeros(2, (len(points)), dtype=np.float64)
    coords[0, :] = [pt.x for pt in points]
    coords[1, :] = [pt.y for pt in points]
    return coords


class Ripleyregion:
    def __init__(self, region: Polygon = None, arcs: int = 100):
        if region:
            self.region = region
        else:
            self.region = Polygon([[0, 0], [1, 0], [1, 1], [0, 1], [0, 0]])
        self.points = []
        self.arcs = _getarcs(arcs)
        self.distance = None
        self.ripley = None

    def addpoint(self, point: Point = None):
        if point:
            if self.region.contains(point):
                self.points.append(point)
            else:
                logging.warning("Tried to add point outside of region.")
        else:
            self.points.append(_get_random_point_in_polygon(self.region))

    def getripleycurve(self) -> np.ndarray:
        """
        Ripley L(r)-r curve
        With:
        - w_cum = the cummlative weights
        - d = distances
        - A = area of the region
        - N = the nr of points in the region
        then f(i) = sqrt((w_cum(i)*(A/N^2))./pi)-d(i)
        :return:
        """
        d, w = self.getweightedsqdistances()
        d_inds = d.argsort()
        d = d[d_inds]
        w = w[d_inds]
        wc = np.cumsum(w)
        self.ripley = np.sqrt((wc * self.region.area / (len(self.points) ** 2)) / np.pi) - d
        self.distance = d
        return np.vstack((self.distance, self.ripley))

    def getweightedsqdistances(self):
        """
        The weighted squared distances for each distance.
        While the distance from pt1->pt2 is the same as pt2->pt1, the weight might not be.
        :return:
        """
        d = np.zeros(len(self.points) ** 2 - len(self.points), dtype=np.float64)
        w = np.zeros(len(self.points) ** 2 - len(self.points), dtype=np.float64)
        i = 0
        for pt1 in tqdm(self.points):
            for pt2 in self.points:
                # from pt1 to pt2
                if pt1 == pt2:
                    continue
                d[i] = np.sqrt((pt1.x - pt2.x) ** 2 + (pt1.y - pt2.y) ** 2)
                arcs = self.arcs * d[i] + np.array((pt1.x, pt1.y), dtype=np.float64)[..., np.newaxis]
                w[i] = 0
                for arc in range(arcs.shape[1]):
                    if self.region.contains(Point(arcs[:, arc])):
                        w[i] += 1
                w[i] /= arcs.shape[1]
                if w[i] == 0:
                    w[i] = -1
                w[i] = 1 / w[i]
                i += 1
        if any(w == -1):
            logging.warning(f"{sum(w == -1)} distances had no arc in the region and are discarded.")
            d = d[w != -1]
            w = w[w != -1]
        return d, w
