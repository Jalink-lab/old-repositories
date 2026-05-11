# -*- coding: utf-8 -*-
"""
Created on Sat Jun  6 12:28:59 2020

@author: keesj
"""

import numpy as np
import matplotlib.pyplot as plt
np.random.seed()

####Section A. create data for 2 known lifetimes allowing various led duty cycles and noise
#part 1. input vars
nrOfPhases=24 #should be even
steps=np.arange(0,2*np.pi, (2*np.pi)/nrOfPhases)
Tau1=3e-9
Tau2=4e-9
Freq=40e6 #40 MHz
dutyCycleAsymetry=0.12 # diff between longest and shortest DC, BUT IN TERMS OF LIGHTOUTPUT! so, up to 15%
dataNoise=0.1 #weighting factor for poisson noise

def phaseShift(F, T):
    return np.arctan(2*np.pi*F*T) 
def demod(F, T):
    return 1/np.sqrt(1+((2*np.pi*F*T)**2))

phaseShift1=phaseShift(Freq, Tau1)
demod1=demod(Freq, Tau1)

#part 2. generate the ensuing sine waves = 'raw data'
def generateSine(offset, steps, demod, phaseShift, dutyError, dataNoise):
    noise=np.zeros(nrOfPhases)
    noise=np.random.normal(noise, dataNoise)
    #first half phases different DC than second half
    dutyErrors=np.ones(steps.size)
    dutyErrors = dutyErrors + dutyError/2
    dutyErrors[0:(int(nrOfPhases/2))]-=dutyError
    out=(dutyErrors*(offset+demod*np.sin(phaseShift+steps)))
    noise=np.sqrt(out) * noise
    return out + noise #note this is just noise, no photon noise, not intensity dependent

sineTau0 = generateSine(1, steps, 1, 0, 0, 0) 
sineTau1 = generateSine(1, steps, demod1, phaseShift1, dutyCycleAsymetry, dataNoise) 
sineTau2 = generateSine(1, steps, demod1, phaseShift1, -dutyCycleAsymetry, dataNoise) 
#plot shows how the same asymetry in LED signal works out in the two registers
plt.plot(steps,sineTau0,  steps, sineTau1, steps, sineTau2)
plt.show()

####Section B. use these simulated data to arrive at calculated phases and demodulations
from scipy import optimize
def functionToFit(x,Mag,Phase):
    return Mag*np.sin(Phase + x) #general fitting routine. slow, but did not want to use same as Rolf

params, ff = optimize.curve_fit(functionToFit, steps, sineTau1)
M1, Ph1=params
print('M, Phi 1 =', params)
fittedCurve=1+ M1*np.sin(steps + Ph1)
plt.plot(steps, fittedCurve, steps, sineTau1)
plt.show()

params, ff=optimize.curve_fit(functionToFit, steps, sineTau2)
M2, Ph2 = params
print('M, Phi 2 =', params)
fittedCurve=1+ M2*np.sin(steps + Ph2)
plt.plot(steps, fittedCurve, steps, sineTau2)
plt.show()

####Section C. generate phasor plots using those fitted data
#part 1. generate semi circle
tauSweep=np.linspace(0, 2e-8,100)
phaseShiftSweep=phaseShift(Freq, tauSweep)
demodSweep=demod(Freq, tauSweep)
xCircleValues=demodSweep*np.cos(phaseShiftSweep)
yCircleValues=demodSweep*np.sin(phaseShiftSweep)
plt.plot(xCircleValues, yCircleValues, '-ok', markersize=2, linewidth=0.2)

#part 2. Plot the fitted data in the same plot
xValue=M1*np.cos(Ph1)
yValue=M1*np.sin(Ph1) 
plt.plot(xValue, yValue, '-o', markersize=2)
xValue= M2*np.cos(Ph2)
yValue = M2*np.sin(Ph2)
plt.plot(xValue, yValue, '-o', markersize=2)
plt.show()

####Section D. plot clouds of points
#remove the next line for a more detailed view of the points
#plt.plot(xCircleValues, yCircleValues, '-ok', markersize=2, linewidth=0.2) # this line to remove optionally

for i in range(1,500): #repeat the essence of the script N times (add noise, fit, plot polar)
    sineTau1 = generateSine(1, steps, demod1, phaseShift1, dutyCycleAsymetry, dataNoise) 
    sineTau2 = generateSine(1, steps, demod1, phaseShift1, -dutyCycleAsymetry, dataNoise) 

    params, ff = optimize.curve_fit(functionToFit, steps, sineTau1)
    M1, Ph1=params
    params, ff=optimize.curve_fit(functionToFit, steps, sineTau2)
    M2, Ph2 = params
    xValue=M1*np.cos(Ph1)
    yValue=M1*np.sin(Ph1) 
    plt.plot(xValue, yValue, '-o', markersize=1, color="blue")
    xValue= M2*np.cos(Ph2)
    yValue = M2*np.sin(Ph2)
    plt.plot(xValue, yValue, '-o', markersize=1, color = "green")
#plt.show()
