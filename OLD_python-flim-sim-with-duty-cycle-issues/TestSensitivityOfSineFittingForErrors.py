# -*- coding: utf-8 -*-
"""
Created on Fri Jun 12 08:07:58 2020
workspace to demonstrate the concept of sensitivity analysis. find out what it does.

Hint: if you do not know yet, find out online what 'curve fitting' is. 
@author: keesj
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy import optimize

offset=1
aantalSteps=24
aantalVariations=21
varRange=0.7

steps=np.arange(0, 2*np.pi, (2*np.pi)/aantalSteps)
sinus=np.sin(steps)
def functionToFit(x,Mag,Phase):
    return Mag*np.sin(Phase + x) #general fitting routine. slow, but very general

varieer=np.arange(-varRange,varRange, 2*varRange/aantalVariations)
dataOut=np.zeros((aantalSteps, aantalVariations, 2), float)

for pos in range(aantalSteps):
    for i in range(aantalVariations):
        sinusVar=np.zeros_like(sinus)
        np.copyto(sinusVar, sinus)
        sinusVar[pos]=sinus[pos]+varieer[i]
        params, ff = optimize.curve_fit(functionToFit, steps, sinusVar)
        M, Ph=params
        dataOut[pos,i,0]=M
        dataOut[pos,i,1]=Ph
        print('M, Phi =', params)
        fittedCurve=M*np.sin(steps + Ph)
        plt.plot(steps, fittedCurve, steps, sinus)
    plt.show()
for pos in range(aantalSteps):
    plt.plot(varieer,dataOut[pos,:,1] ) 
plt.show()
for pos in range(aantalSteps):
    plt.plot(varieer,dataOut[pos,:,0] ) 
plt.show()
sensitivityM=np.zeros(aantalSteps)
sensitivityPh=np.zeros(aantalSteps)
for y in range(aantalSteps):
    sensitivityM[y]=sum(np.sqrt((dataOut[y,:,0]-1)**2))
    sensitivityPh[y]=sum(np.sqrt(dataOut[y,:,1]**2))
plt.plot(steps, sensitivityM, steps, sensitivityPh)
plt.show
