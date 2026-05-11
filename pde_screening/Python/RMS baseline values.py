# -*- coding: utf-8 -*-
"""
Created on Mon May 10 14:14:54 2021

@author: keesj
"""
from pathlib import Path
import numpy as np
from matplotlib import pyplot as plt
from numpy import genfromtxt

root = Path('E:\\pde_screening_data')
pth = Path(root,'Screening_Data_Analyzed','2019','12','05','caged','results')
files = [x for x in pth.glob('**/*_tau.csv') if x.is_file()]  # all 163 tau.csv files

all_data = []
for file in files:
    data = genfromtxt(file, delimiter='\t')
    sh = data.shape
    for i in range(0,sh[0]):
        all_data.append(data[i][0:12])

all_data = np.stack(all_data,axis=0)

dims = all_data.shape
all_std = np.zeros((dims[0]), dtype=np.float64)
for i in range(0,dims[0]):
    all_std[i] = all_data[i].std()
    
plt.hist(all_std, bins=1000);
plt.xlim(0,1)
plt.xlabel('RMS (ns)')
plt.ylabel('#')
print(f"Mean RMS = {all_std.mean()*1000:.0f} ps")

count=0
for i in all_std:
    if i>0.05:
        count=count+1
print(count)
