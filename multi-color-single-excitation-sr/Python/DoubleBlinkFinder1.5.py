# -*- coding: utf-8 -*-
"""
Created on Wed Mar  6 12:41:45 2019
Finds corresponding blinks in the left and right parts of the split image, per frame
@author: k.jalink
"""
import numpy as np
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
fname ="D:/temp/DC_SR/Kees/RainBowTest/left.csv"
lData=np.loadtxt(fname, delimiter=",", skiprows=1 )
fname ="D:/temp/DC_SR/Kees/RainBowTest/right.csv"
rData=np.loadtxt(fname, delimiter=",", skiprows=1 )
#initialize blink linking array
linkedBlinks=np.arange(1,19).reshape(1,18)
blinkDisplacement=np.arange(1,6).reshape(1,5) #reminder: remove it at the end
nrOfFramesToAnalyze = 90
seekRange=100 # in nm
offsetX = 86
offsetY = 48
anchors=20
anchorData=np.zeros(anchors*anchors*4).reshape(anchors*anchors,4)

#now start looking for split blinks in each frame. for i in range(0,(lFrame.shape[0]-1)):
print("analyzing ", nrOfFramesToAnalyze," frames")
for frameNr in range(1,(nrOfFramesToAnalyze+1)):
    lFrame=kjCopyFrame(lData,frameNr)
    rFrame=kjCopyFrame(rData,frameNr)
    for i in range(0,(lFrame.shape[0]-1)):
        for j in range (0, (rFrame.shape[0]-1)):
            difX=lFrame[i,2] - rFrame[j,2]+offsetX
            if abs(difX)<seekRange:
                difY=lFrame[i,3] - rFrame[j,3]+offsetY  
                if abs(difY)<seekRange:
                    a=np.sqrt(difX**2+difY**2)
                    ff=np.concatenate((lFrame[i,:],rFrame[j,:]),0).reshape(1,18)
                    linkedBlinks=np.vstack((linkedBlinks,ff))
                    fff=np.zeros(5).reshape(1,5) 
                    fff[0,:]=[difX, difY, a, lFrame[i,2], lFrame[i,3]]
                    blinkDisplacement=np.vstack((blinkDisplacement,fff)) #who is the master? Kees!
    print(frameNr) #optionally; to see the progress
meanX=blinkDisplacement[:,0].mean()
meanY=blinkDisplacement[:,1].mean()                  
print("mean displacement", meanX, meanY)

kjScatterPlotWrapper(blinkDisplacement[:,0],blinkDisplacement[:,1])
kjQuiverPlotWrapper(blinkDisplacement[:,3], blinkDisplacement[:,4], blinkDisplacement[:,0], blinkDisplacement[:,1])

for i in range(0, anchors):
    iMax=1000*i+500
    iMin=1000*i-500
    for j in range(0, anchors):
        jMax=1000*j+500
        jMin=1000*j-500 #watch and awe! the next code is pure beauty!
        q=np.logical_and((np.logical_and(blinkDisplacement[:,3]<iMax, blinkDisplacement[:,3]>iMin)),(np.logical_and(blinkDisplacement[:,4]<jMax, blinkDisplacement[:,4]>jMin)))
        R=blinkDisplacement.compress(q,0)  
        anchorData[i+j*anchors,:]=[i,j, R[:,0].mean(),R[:,1].mean()]
#print(anchorData)
kjQuiverPlotWrapper(anchorData[:,0],anchorData[:,1],anchorData[:,2],anchorData[:,3] )
     
        
