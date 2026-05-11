# -*- coding: utf-8 -*-
"""
Created on Wed Mar  6 12:41:45 2019
Finds corresponding blinks in the left and right parts of the split image, per frame
@author: k.jalink
"""
import numpy as np
import time
import matplotlib 
import matplotlib.pyplot as plt
from matplotlib.ticker import NullFormatter

def kjCopyFrame(srcData, FrameNr):
    #kj, March 2019. Takes a subset of FrameNr frames out of a Thunderstorm CSV file
    v=(FrameNr==srcData[:,1])
    Frame=srcData.compress(v,0)
    return Frame #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


def kjScatterPlotWrapper(x,y):
    # KJm March 2019. stolen from the example file. Takes two vectors (x and y coordinates)
    #as input and plots scatterplot and histograms X and Y
    nullfmt = NullFormatter()         # no labels
    # definitions for the axes
    left, width = 0.1, 0.65
    bottom, height = 0.1, 0.65
    bottom_h = left_h = left + width + 0.02
    rect_scatter = [left, bottom, width, height]
    rect_histx = [left, bottom_h, width, 0.2]
    rect_histy = [left_h, bottom, 0.2, height]
    
    # start with a rectangular Figure
    plt.figure(1, figsize=(12, 12))
    axScatter = plt.axes(rect_scatter)
    axHistx = plt.axes(rect_histx)
    axHisty = plt.axes(rect_histy)
    # no labels
    axHistx.xaxis.set_major_formatter(nullfmt)
    axHisty.yaxis.set_major_formatter(nullfmt)
    
    # the scatter plot:
    axScatter.scatter(x,y,1,'k')
    # now determine nice limits by hand:
    binwidth = 1
    xymax = max(np.max(np.abs(x)), np.max(np.abs(y)))
    lim = (int(xymax/binwidth) + 1) * binwidth
    
    axScatter.set_xlim((-lim, lim))
    axScatter.set_ylim((-lim, lim))
    
    bins = np.arange(-lim, lim + binwidth, binwidth)
    axHistx.hist(x, bins=bins)
    axHisty.hist(y, bins=bins, orientation='horizontal')
    
    axHistx.set_xlim(axScatter.get_xlim())
    axHisty.set_ylim(axScatter.get_ylim())
    plt.show() #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   
    
def kjQuiverPlotWrapper(X,Y,U,V):
    #kj, March 2019. Stolen from example files. Plots quiverplot from coordinates
    # (X,Y) to ((X+U),(Y+V)). 
    fig2, ax1 = plt.subplots(figsize=(12,12)) # moet dit fig2 zijn? of Fig 1?
    ax1.set_title('Arrows scale with plot width, not view')
    ax1.quiver(X, Y, U, V)#, units='width')
    plt.show() #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  
    
    
    
# MAIN SCRIPT starts >>>>>>>>>>>>  
# this one compares the position of blinks in the left and right frame. First
    #run it with a limited set of frames to determine mean X and Y shift.
    #then fill in those offsets and run it again for more frames
fname ="G:/RainBowTest/other example/left.csv"
lData=np.loadtxt(fname, delimiter=",", skiprows=1 )
fname ="G:/RainBowTest/other example/right.csv"
rData=np.loadtxt(fname, delimiter=",", skiprows=1 )
nrOfRows=lData.shape[0]
#initialize blink linking array
linkedBlinks=np.zeros([nrOfRows,18])
blinkDisplacement=np.zeros([nrOfRows, 5]) #reminder: remove it at the end
nrOfFramesToAnalyze = 9000
seekRange=150 # in nm
offsetX =-10
offsetY =20
anchors=40 #to be distributed evenly along the 20x20 um image
anchorRange = 20000 / (2 * anchors) # half the distance between two anchors, in nm
anchorData=np.zeros(anchors*anchors*4).reshape(anchors*anchors,4)

#now start looking for split blinks in each frame. for i in range(0,(lFrame.shape[0]-1)):
print("analyzing ", nrOfFramesToAnalyze," frames")
kjBeginTijd=time.time()
blink=0
for frameNr in range(1,(nrOfFramesToAnalyze+1)):
    kjTijd=time.time()
    lFrame=kjCopyFrame(lData,frameNr)
    rFrame=kjCopyFrame(rData,frameNr)
    for i in range(0,(lFrame.shape[0]-1)):
        for j in range (0, (rFrame.shape[0]-1)):
            difX=lFrame[i,2] - rFrame[j,2]+offsetX
            if abs(difX)<seekRange:
                difY=lFrame[i,3] - rFrame[j,3]+offsetY  
                if abs(difY)<seekRange:
                    a=np.sqrt(difX**2+difY**2)
                    linkedBlinks[blink,:] = np.append(lFrame[i,:],rFrame[j,:])
                    blinkDisplacement[blink,:]=[difX, difY, a, lFrame[i,2], lFrame[i,3]] #who is the master? Kees!
                    blink=blink+1
    print(frameNr, "= FrameNr, took %4.2f s,      total time is %4.2f s"%((time.time()-kjTijd),(time.time()-kjBeginTijd)))
meanX=blinkDisplacement[:,0].mean()
meanY=blinkDisplacement[:,1].mean()                  
print("mean displacement", meanX, meanY)
#Next, trim the sizes of arrays to the nr of coincidences
blinkDisplacement=blinkDisplacement[0:blink,:]
linkedBlinks=linkedBlinks[0:blink,:]

kjScatterPlotWrapper(blinkDisplacement[:,0],blinkDisplacement[:,1])
kjQuiverPlotWrapper(blinkDisplacement[:,3], blinkDisplacement[:,4], blinkDisplacement[:,0], blinkDisplacement[:,1])

for i in range(0, anchors):
    iMax=(2*anchorRange)*i+anchorRange
    iMin=(2*anchorRange)*i-anchorRange
    for j in range(0, anchors):
        jMax=(2*anchorRange)*j+anchorRange
        jMin=(2*anchorRange)*j-anchorRange #watch and awe! the next code is pure beauty!
        q=np.logical_and((np.logical_and(blinkDisplacement[:,3]<iMax, blinkDisplacement[:,3]>iMin)),(np.logical_and(blinkDisplacement[:,4]<jMax, blinkDisplacement[:,4]>jMin)))
        R=blinkDisplacement.compress(q,0)  
        anchorData[i+j*anchors,:]=[i,j, R[:,0].mean(),R[:,1].mean()]
#print(anchorData)
kjQuiverPlotWrapper(anchorData[:,0],anchorData[:,1],anchorData[:,2],anchorData[:,3] )
     
        
