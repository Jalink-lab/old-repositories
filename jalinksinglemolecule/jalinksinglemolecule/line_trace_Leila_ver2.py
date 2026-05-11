#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu May 21 09:45:29 2020

@author: l.nahidiazar
"""

# eenheidlint is a line which will be drawn with an angle given by user (arrow) 
# and will be started form the point being defined by user. 

import numpy as np
import matplotlib.pyplot as plt
#import math
from jalinksinglemolecule import ThunderStormFile


class point(object):
    '''Creates a point on a coordinate plane with values x and y.'''

    COUNT = 0

    def __init__(self, x, y):
        '''Defines x and y variables'''
        self.X = x
        self.Y = y

    def move(self, dx, dy):
        '''Determines where x and y move'''
        self.X = self.X + dx
        self.Y = self.Y + dy

    def getX(self):
        return self.X

    def getY(self):
        return self.Y

  
def cal_circle(circles, mypoint):
    
    xc = mypoint.getX()
    yc = mypoint.getY()
    r = 200 #radius
    arr_xp = [] 
    arr_yp = []
    arr_newpoint = []
    for i in range(60):
            xp = xc + r*(np.cos(np.pi*i/180))
            yp = yc + r*(np.sin(np.pi*i/180))
            arr_xp.append([xp])
            arr_yp.append([yp])
            b = np.array([xp, yp])
            print(b)
            print('coordinates of line' + str(i) + 'is' + str(b))
            point1 = [xp, xc]
            point2 = [yp, yc]
            plt.plot(point1, point2)
            c = np.array([point1, point2, r])
            # print(c)
            arr_newpoint.append([c])
            
            
    print(arr_newpoint)    
    print(arr_xp)
    print(arr_yp)
    print(len(arr_xp))
    plt.plot(xc, yc, '.')
    plt.plot(arr_xp,arr_yp, '.')
       

#to find out how many localizations in a defined range.  
    arr_localz = []   
    ts_a532 = ThunderStormFile('10-200128+HT1080WT+LaminBA532_chromcorr.csv')
    ts_a532.make_kdtree()
    pt = [xc, yc]
    r = 200
    pts_in_circle = ts_a532.kdtree.query_ball_point(pt, r)  # a ball query requests all points in a circle
    print(f"found {len(pts_in_circle)} points in circle")
    arr_localz.append(pts_in_circle[xc, yc])
    print(arr_localz)  
    
    
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
        
    for i < len(arr_localz.index(0:)) 
        if #tht specific point of the localizations in the circle overlpas 
        #with the line? if yes, icrease the counter. 
        #otherwose go to the next point.
    
    # xc = xp
    # yc = yp    
   
   