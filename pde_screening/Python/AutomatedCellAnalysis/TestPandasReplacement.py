# -*- coding: utf-8 -*-
"""
Created on Thu Feb 18 05:08:29 2021

@author: keesj
"""
import pandas as pd
import numpy as np
data=np.random.uniform(0,10,300000000)

df=pd.DataFrame(data)
df.head()
df2=df

def kj():
    for i in range(200):
        df2[i]=df[i]*10

kj()

