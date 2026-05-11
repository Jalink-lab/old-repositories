# -*- coding: utf-8 -*-
"""
Created on Tue Jul 21 13:08:30 2020
LaserEtch. script to etch laserpictures from photos. 2nd, somewhat optimized version.
Ues only basic Gcode syntax so should run on most any CNC machines. Settings are
changed directly in the script in the section 'settings'.
@author: keesj.
"""
# steps: import pic into np array
# go to each pixel and modulate laser
# make Gcode in text file
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
import os

#%matplotlib inline
inIm=mpimg.imread("C:/dataff/foto.png") #natively accepts png 8bit B/W images only
imgplot=plt.imshow(inIm)

laserStart="M3"
laserStop="M5"

######### -------------------------SETTINGS
cropTopLeft=(0,0)           #(Y,X) or lines, columns
cropBottomRight=(3000,4000) #this sets the cropping range. the image anIm is the one that will be etched.
anIm=inIm[cropTopLeft[0]:cropBottomRight[0],cropTopLeft[1]:cropBottomRight[1]] #this selects a crop out of the original image. this one is the one that will be etched.
#anIm=inIm[cropTopLeft[0]:cropBottomRight[0],cropTopLeft[1]:cropBottomRight[1]]
imgplot=plt.imshow(anIm)

#now the image is in the matrix. Next, make a laser plot file of it.
laser=40                    #actual laser level; ~50 is zero output, 5000 is max (5W)
maxLaser=1500               #maxiumum = dark level for this image
minLaser=60                 #off-level
#input values are 0-1 (1= bright); output values minLaser-maxLaser
laserRange= maxLaser-minLaser
gamma=2                     #gamma (float) corects for the fact that burning is not linear 
                            #with laser power. 1 is no gamma, 2 is softer contrasts.
pixelPause=0.005
plotSpeed=300

outSizeX=100                #outSize width in mm
outSizeY=100                #outSize height in mm
picHeight, picWidth=anIm.shape
picScale=outSizeX/picWidth
linesPerMilliMeter=4    #sets the resolution (lines per mm)
subSample=picWidth/(outSizeX*linesPerMilliMeter) #if image has more resolution, subsample the image
subSample=round(0.5+subSample)

#shoIm=(1-anIm)**gamma      #these two lines show how the gamma works on the cropped region
#imgplot=plt.imshow(shoIm)

####### --------------------------------------END SETTINGS

#######-->>main plotroutine
rootName='C:/dataff/laserSketch.txt'  #output goes to the one and only universal folder :)
nr=0
while os.path.exists(rootName): #if file exists, raise the index nr and use that filename
    nr=nr+1
    rootName='C:/dataff/laserSketch'+str(nr)+'.txt'
fileOut = open(rootName, 'w') #generate file


fileOut.write('M05 S0 \n')  #start and goto 0,0
fileOut.write('G90 \n')
fileOut.write('G21 \n')     #use mm instead of inch
fileOut.write('F'+str(plotSpeed)+' \n')
fileOut.write('G1 X0 Y0 \n')
fileOut.write('S60 \n')     #set laserMin
fileOut.write('P0.1 \n')    #generate Pause

for i in range(0, picHeight, subSample):
    iScale=i*picScale   
    fileOut.write('F1500 \n')    
    fileOut.write('G1 X0 Y'+str(iScale)+' \n')  #generate fast G1 x=0, y=i
    fileOut.write('F'+str(plotSpeed)+' \n') 
    fileOut.write(str(laserStart)+' \n')        #generate laserStart

    for j in range(0, picWidth, subSample):
        jScale=j*picScale
        laser=minLaser+((1-anIm[i,j])**gamma)*laserRange
        fileOut.write('G1 X'+str(jScale)+' Y'+str(iScale)+' \n') #goto next pixel
        fileOut.write('S'+str(laser)+' \n')             #output laser intensity
        fileOut.write('P'+str(pixelPause)+' \n')        #output Pause text
        
    print('next line is ', i)
    fileOut.write(str(laserStop)+' \n')     #generate laserStart
    fileOut.write('S40 \n')                 #set to laser low
    fileOut.write('P0.1 \n')                #generate Pause
fileOut.close()
    
#still to do: bidirectional etching and averaging in case of subsampling
#error checking on crop sizes; what when width=2000 and height is 10, etc

    
        
        
        
        
        
        
        