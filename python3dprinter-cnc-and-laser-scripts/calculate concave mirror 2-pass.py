# -*- coding: utf-8 -*-
"""
Created on Fri Aug  7 17:36:07 2020
solar reflector calc. mirror of 1 square meter, radius of 20m has a focus of 10 meter.
V2. will calculate the gcode while using millbit diameter and using path optimization
@author: keesj
"""
import numpy as np
#import matplotlib.pyplot as plt
#import matplotlib.image as mpimg
import os

#Set up a 2d array between -0.5*mirrorsize and +0.5* mirrorsize and calculate for every x and y what the Z should be
spindleStart="M3"
spindleStop="M5"
millSpeed=200              #velocity of mill travel when milling
fastSpeed=800               #velocity when moving between mills
saveHeight=3                #clearance from surface when traveling, in mm
coarseResolution=1          #in mm. this is the overlap between concentric mills. settin 1 with a 2 mm bit makes 50% overlap
millRadius=1                #bit radius in mm
ring=3                      #when finemilling, no need to do pockets. Mill rings with this width instead. in mm
zStep=0.4                   #in mm. It mills down by this much in very cycle
stayAway=0.15                #in mm. during coarse milling, it leaves the final surface free by this much
sphereRadius=800            #defines the concave mirror, together with sphereCentre
sphereCentre=796

def millPocket(z, outerRadius, innerRadius=0, millRadius=1, centre=(0,0), resolution=0.5, saveHeight=3):
    # milling a circle with G2 or G3 code: start point, left point of the circle,  is current pos, end point is X, Y; 
    # centre is a vector I,J away from the starting point. Full circle: no X and Y specified. If
    #innerRadius>mill diameter, it mills a ring-shaped pocket
    fileOut.write('G1 Z'+str(saveHeight)+'\n')  #go to saveheight
    radius=outerRadius-millRadius
    while radius>(innerRadius+millRadius):
        if (radius+millRadius) <  innerRadius:
            radius=innerRadius+millRadius      
        fileOut.write('G1 X'+str(-radius)+' \n')
        fileOut.write('G1 Z'+str(z)+' \n')  #go to (or stay at) milling height                 
        fileOut.write('G2 I'+str(radius)+' \n')
        radius = radius - resolution
    fileOut.write('G1 Z'+str(saveHeight)+'\n')  #go to saveheight
        

maxDepth=sphereCentre-sphereRadius # the surface= depth 0, so the mirror goes to negative Z values
#for the outer circle, height^2 + circleRadius^2 = sphereRadius^2
circleRadius=np.sqrt((sphereRadius**2)-(sphereCentre**2))
print('depth at centre is '+str(maxDepth)+' mm')
print('sphere radius is '+str(sphereRadius)+' mm')
print('mirror radius is '+str(circleRadius)+ ' mm')


#######-->>main plotroutine
rootName='C:/dataff/MirrorMillConcentric.txt'  #output goes to the one and only universal folder :)
nr=0
while os.path.exists(rootName): #if file exists, raise the index nr and use that filename
    nr=nr+1
    rootName='C:/dataff/mirrorMillConcentric'+str(nr)+'.txt'
fileOut = open(rootName, 'w') #generate file
fileOut.write('F'+str(fastSpeed)+' \n')
fileOut.write('G1 Z'+str(saveHeight)+'\n')  #go to saveheight
fileOut.write('M05 S0 \n')  #start and goto 0,0
fileOut.write('G90 \n')
fileOut.write('G21 \n')     #use mm instead of inch
fileOut.write('G1 X0 Y0 \n')
fileOut.write('S3500 \n')     #set mill speed
fileOut.write('F'+str(millSpeed)+' \n')
fileOut.write('P0.1 \n')    #generate Pause

# # from here on it is radically different. First mill down in concentric circles with big steps
# fileOut.write(str(spindleStart)+' \n')        #generate laserStart
depth=-zStep
while depth>(maxDepth+stayAway):
    #find out what pocket to mill and then mill it
    radius=np.sqrt((sphereRadius**2)-((sphereCentre+stayAway-depth)**2))
    millPocket(depth, radius, 0, millRadius, (0,0), coarseResolution, saveHeight)   
    depth=depth-zStep
    
# Than do a final pass for smooth milling the last details
zStep=0.04
stayAway=0
millSpeed=250

fileOut.write('G1 Z'+str(saveHeight)+'\n')  #go to saveheight
depth=-0.0
while depth>maxDepth:
    #find out what ring to mill and then mill it
    radius=np.sqrt((sphereRadius**2)-((sphereCentre+stayAway-depth)**2))
    millPocket(depth, radius, (radius-ring), millRadius, (0,0), coarseResolution, saveHeight)   
    depth=depth-zStep

fileOut.write('G1 Z'+str(saveHeight)+'\n')  #go to saveheight    
fileOut.write('P0.1 \n')                    #generate Pause
fileOut.write(str(spindleStop)+' \n')       #stop the spindle
fileOut.close()




