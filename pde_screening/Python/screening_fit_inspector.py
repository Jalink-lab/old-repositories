# -*- coding: utf-8 -*-
"""
Created on Mon Sep 28 21:28:29 2020
Quick and dirty, modified from the jptnb of Rolf and Olga to scroll through all cells 
of a particular well. Make sure to select 'inline' plotting in preferences/graphics, 
or run %matplotlib inline in the console

First, modify the well you want to see in line 20. Then run, and use <enter> in the
console to scroll through the cells
@author: keesj
"""
import pandas as pd
import time
from pathlib import Path
from matplotlib import pyplot as plt
import numpy as np
import tkinter as tk
from tkinter import filedialog
from AutomatedCellAnalysis.get_cell_image import get_cell_image
from sys import exit

ROOT = tk.Tk()
ROOT.withdraw() #closes the tkinter window again. just a cleanup
ROOT.attributes('-topmost', True)

#<<<<<BLOCK: some settings to shape the inspection flow
autoScroll=True #automatically scrolls through the cells
randomCells=True #only show a few (max_nroi) examples
pickSpecificCell=True #only show (a) specific cell(s)
if pickSpecificCell==True:
    randomCells=False
fixYScale = True
max_nroi=4 #<<<<<<<<<< adjust this one to set how many are plotted maximally per well
scrollTime=0.5        #autoscroll delay, in s

#<<<<<BLOCK: remember the last results folder
name_of_base_path_file="C:\Current_Python_Results_Path.txt" #this file is written in C:\ (root) to remember base path
if Path(name_of_base_path_file).exists():
    base_path = open(name_of_base_path_file, 'r').read()
else:   
    base_path = Path('C:\\')  
    
users_base_path = filedialog.askopenfilename(title="Choose a single well fit file",
                                          initialdir=base_path, filetype=(('csv files', '*.csv'),("all files", "*.*")))
print(users_base_path) 
fileName=users_base_path.split("/")[-1] # next, determine the names of the corresponding _fit.csv and _tau.csv files
resultpath=users_base_path.rstrip(fileName)# the path without the filename

text_file = open(name_of_base_path_file, "w") # note: you need write permission to root of C: !!!!
text_file.write(resultpath)# returns code 29 if it worked OK
text_file.close()

#<<<<<<<<BLOCK: set up filenames and read data and meta data
users_base_path = Path(users_base_path)
labelmap_pth = Path(users_base_path.parent.parent,'intensity_data',users_base_path.name[:-8]+'_I_mean_labelmap.tif')
meanimg_pth = Path(users_base_path.parent.parent,'intensity_data',users_base_path.name[:-8]+'_I_mean.tif')

wellName=fileName[0:len(fileName)-8]
resultfile = wellName+'_tau.csv' 
fitfile = wellName+'_fit.csv'

fit = pd.read_csv(Path(resultpath,fitfile))
condition=fit['condition'][0]
lifetimetraces = np.loadtxt(Path(resultpath,resultfile))
frameinterval = fit['frameinterval(s)'][0]
forskendpoint = True
nroi = min(lifetimetraces.shape[0], max_nroi) #plot no more than max_nroi cells if they exist
ntime = lifetimetraces.shape[1]

#<<<<<<<<BLOCK: select cells based on fitting errors and boundaries
fit_sel = fit[fit['breakdown_time(s)'] > -1]#these are conditions added by Rolf to reject some cells
#fit_sel = fit_sel[fit_sel['error']==0]
print('There are '+ str(len(lifetimetraces)) +' individual cells in the FOV of well '+wellName)
print('There are '+ str(len(fit_sel)) +' individual cells that qualify as a good-enough fit')
print("    --")

def fit_function(x, a, b, c, d):
    return a + b / (1 + np.exp(-4 * (x - d)/c)) 

#<<<<<<<BLOCK: implement flexibility in picking cells
selectedCells=np.arange(0, max_nroi,1) #limit 0-max_nroi
if randomCells==True:
    selectedCells = np.random.randint(1, len(lifetimetraces), size=max_nroi)
if pickSpecificCell==True:
    ff=(input("enter valid roinumbers of cell(s) separated by a space and press Enter to accept: "))
    selectedCells=np.asarray(ff.split(" ")).astype((np.int))
    if selectedCells.max()>len(lifetimetraces):
        print("INVALID ROI Nr(s). Try again")
        exit()

#<<<<<<<BLOCK: start main loop
for trace_id in selectedCells:
    fit_vals= fit.loc[trace_id,:]
    fit_vals
    xdat = np.arange(0, ntime * frameinterval, frameinterval)
    ydat = lifetimetraces[trace_id]   
    yfit = fit_function(xdat,fit_vals['start(ns)'],fit_vals['range(ns)'],fit_vals['breakdown_time(s)'],fit_vals['midpoint(s)'])
    print(wellName,"  ", condition,"  ", "Cell ", trace_id,  '       n_x =', len(xdat), '  n_y =', len(ydat),'  n_yfit =', len(yfit))
    
    # find the fit-range
    fitrange = np.zeros(shape=2, dtype=int)
    mean_trace = np.mean(lifetimetraces, axis=0)
    
    d_mean_trace = np.diff(mean_trace)
    fitrange[0] = np.argmax(mean_trace[0:int(150 / frameinterval)])  # maximum in the first 150 seconds
    fitrange[1] = ntime
    if forskendpoint:
        # 3 frames before maximum increase after peak.
        fitrange[1] = fitrange[0] + np.argmax(d_mean_trace[fitrange[0]:]) - 1
    
    xdat_selected = xdat[fitrange[0]:fitrange[1]]
    ydat_selected = ydat[fitrange[0]:fitrange[1]]
    yfit_selected = yfit[fitrange[0]:fitrange[1]]
    
    yresid = ydat - yfit #generate residuals but only for fit region
    yresid[0:fitrange[0]]=0
    yresid[fitrange[1]:len(yresid)]=0    
    
    rect_fit = [0.1, 0.5, 1, 1] #double plot the stuff
    rect_resid = [0.1, 0.1, 1, 0.4]
    rect_image = [1.2, 0.1, 1, 1.4]
    fig = plt.figure(figsize = (6*1.4, 6))
    pltFit = fig.add_axes(rect_fit)
    pltResid = fig.add_axes(rect_resid)
    pltImg = fig.add_axes(rect_image)
    pltFit.set_title("Well "+wellName+'-- '+condition+' --Cell '+str(trace_id)+' of '+str(len(lifetimetraces)))
    pltFit.set_ylabel('lifetime (ns)')
    if fixYScale==True:
        pltFit.set_ylim(1.75, 3.5)
    pltResid.set_ylabel('residuals (ns)')
    pltResid.set_xlabel('time (s)')
    pltFit.plot(xdat, ydat, label="exp data")
    pltFit.plot(xdat, yfit, label='fit')
    pltResid.plot(xdat, yresid)
    pltResid.hlines(0,0,len('time (s)')*frameinterval)
    highlighted_ROI = get_cell_image(labelmap_pth,meanimg_pth,trace_id+1)
    pltImg.imshow(highlighted_ROI)
    plt.show()
       
    #  Calculate some measure of fit quality. The residual sum of squares is used to 
    #help you decide if a statistical model is a good fit for your data. 
    SSresid = sum(yresid[fitrange[0]:fitrange[1]]**2)  # The Total SS (TSS or SST) 
    #tells you how much variation there is in the dependent variable. 
    #SStotal = Σ((Yi – mean of Y)**2). or also people use: SStotal = n*var(Y)
    SStotal = len(ydat[fitrange[0]:fitrange[1]]) * np.var(ydat)
    Rsq = 1-(SSresid/SStotal)
    print("SSresid = %.2f"%SSresid, "   ", "SStotal = %.2f"%SStotal, "   ", "Rsq = %.2f"%Rsq)
    RMSD = np.sqrt(SSresid / len(ydat[fitrange[0]:fitrange[1]]))
    
    #The mean absolute percentage error (MAPE), also known as mean absolute percentage deviation (MAPD),
    #is a measure of prediction accuracy of a forecasting method in statistics, for example in trend estimation.
    #It usually expresses the accuracy as a ratio defined by the formula:
    # MAPE = (1/n) * Σ(|actual – forecast| / |actual|) * 100 
    # The smaller the error, again the better! Below 1% is a good measure for goodness of fit.
    
    MAPE = (100/len(ydat_selected))*sum(abs(ydat_selected-yfit_selected) / ydat_selected)
    print("RMSD = %.3f ns"%RMSD,"   ","MAPE = %.1f"%MAPE, "%")   
    print("    --")
   
    trace_id+=1 #next part controls how they are shown sequentially
    if autoScroll==True:
        time.sleep(scrollTime)
    else:
        a=input("type Enter for Next Trace, or s+Enter to Stop: ")
        if a.lower()=='s':
            exit()
           
    
