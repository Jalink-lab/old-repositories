# -*- coding: utf-8 -*-
"""
Created on Fri Aug  7 17:36:07 2020
solar reflector calc. mirrot of 1 square meter, radius of 20m has a focus of 10 meter.
@author: keesj
"""
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
import os

#Set up a 2d array between -0.5*mirrorsize and +0.5* mirrorsize and calculate for every x and y what the Z should be
spindleStart="M3"
spindleStop="M5"
pixelPause=0.005
millSpeed=130
fastSpeed=600
saveHeight=3
outSizeX=100                #outSize width in mm
outSizeY=100                #outSize height in mm; for now only square mirrors
sphereRadius=1000
resolution=5                #in points per mm
drillRadius=1               #in mm
zStep=0.2                   #in mm
startLinePos=-1             #these two vars have to be dseclared here to be global outside the for loop
stopLinePos=-1
mirrorSize=1+ outSizeX*resolution

mirror=np.zeros((mirrorSize,mirrorSize))
for x in range(mirrorSize):
    for y in range(mirrorSize):
        mirror[x,y]=np.sqrt((sphereRadius**2) + (-0.5*(outSizeX)+x/resolution)**2 +(-0.5*(outSizeY)+y/resolution)**2)-sphereRadius      
# don't forget to set: %matplotlib inline or qt as needed
imgplot=plt.imshow(mirror)
plt.colorbar()
maxDepth=-mirror[0,0] #we will define 0 as the surface of the wood to carv from
mirror=mirror+maxDepth #translate the top of mirror to 0

#######-->>main plotroutine
rootName='C:/dataff/laserSketch.txt'  #output goes to the one and only universal folder :)
nr=0
while os.path.exists(rootName): #if file exists, raise the index nr and use that filename
    nr=nr+1
    rootName='C:/dataff/mirrorMill'+str(nr)+'.txt'
fileOut = open(rootName, 'w') #generate file
fileOut.write('M05 S0 \n')  #start and goto 0,0
fileOut.write('G90 \n')
fileOut.write('G21 \n')     #use mm instead of inch
fileOut.write('F'+str(millSpeed)+' \n')
fileOut.write('G1 X0 Y0 \n')
fileOut.write('S3500 \n')     #set mill speed
fileOut.write('P0.1 \n')    #generate Pause

# scan all the coordinates for the mirror matrix. if < that the current depth, start a new mill line
# until it goes higher than the depth, in that case, write line and then 
fileOut.write(str(spindleStart)+' \n')        #generate laserStart
depth=0
while depth>maxDepth:
    depth=depth-zStep
    for y in range(0, mirrorSize):
        startLinePos=-1
        stopLinePos=mirrorSize
        for x in range(0, mirrorSize):
            if startLinePos==-1:
                if mirror[x,y]<depth:
                    startLinePos=x
            if startLinePos>-1:
                if mirror[x,y]<depth:
                    stopLinePos=x 
        # at end of this for-loop begin and endpoint of milling line have been determined.
        #print(y, x, depth, startLinePos, stopLinePos)
        
        if startLinePos>-1:
            xPos=startLinePos/resolution
            xPosEnd=stopLinePos/resolution
            yPos=y/resolution   
            fileOut.write('F'+str(fastSpeed)+'\n')
            fileOut.write('G1 Z'+str(saveHeight)+' \n')  #generate fast Zstep up
            fileOut.write('P0.1 \n')                #generate Pause
            fileOut.write('G1 X'+str(xPos)+' Y'+str(yPos)+' Z'+str(saveHeight)+' \n')  #generate fast G1 to startLinePos
            fileOut.write('G1 Z'+str(depth+0.3)+'\n')  #quickly go to just above surface
            fileOut.write('F'+str(millSpeed)+'\n')
            fileOut.write('G1 Z'+str(depth)+'\n')  #slowly go to surface
            fileOut.write('G1 X'+str(xPosEnd)+' Y'+str(yPos)+' \n')
    fileOut.write('P0.1 \n')                #generate Pause
fileOut.write(str(spindleStop)+' \n')       #stop the spindle
fileOut.close()

# to add: diameter of drillbit, and big steps where that is possible.
# Or go concentric? Go zigzag. Go z-based milling (not in 0.2mm steps) as a finishing layer

