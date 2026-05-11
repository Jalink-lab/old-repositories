# -*- coding: utf-8 -*-
"""
Created on Mon Dec  9 20:40:05 2019                  @author: keesj
it expects a groottexgrootte raw image, 8 bit, with circle, square or triangle (1,2 or 3) 
in a trainAantal-deep stack in folder c:\dataff and with name x_train etc. Also 
a groundthuth named y_train (etc) of shape testAantal x 1. Values are read from 
a descriptor.txt file saved by ImageJ
"""
import numpy as np
import matplotlib.pyplot as plt
#pip install --upgrade tensorflow  # I guess only needed once
import tensorflow as tf #this has imported tensorflow 2.0
from random import seed
from random import randint
seed() # seed random number generator

#=====================================KJ data import section
path='C:/dataff/kjDescriptor.txt'
descriptor= np.loadtxt(path, dtype=np.uint32, delimiter='\t')
trainAantal=descriptor[0]
testAantal=descriptor[1]
grootte=descriptor[2]


path='C:/dataff/x_test'
x_test=np.fromfile(path, dtype=np.uint8).reshape(testAantal,grootte,grootte)
#plt.imshow(x_test[3,:,:])

path='C:/dataff/y_test.txt'
y_test= np.loadtxt(path, dtype=np.uint8, delimiter='\t')
#====================================ends

#now lets do data normalization. not strikt necessary but should make less color-dependent
x_test_norm = tf.keras.utils.normalize(x_test, axis=1)

new_model = tf.keras.models.load_model('c:\dataff\kjImagesModel')
predictions = new_model.predict(x_test_norm)
#print(predictions)# these are the probablities that the pic is each of 0-9

types={1: "closed round", 2: "closed square", 3: "closed triangle", 4: "open circle", 5:"open box", 6:"open triangle" }


columns = 10
rows = 5
fig=plt.figure(figsize=(columns*2, rows*2.4))

wrong = 0
for i in range(1, columns*rows +1):
    rndWaarde=randint(1,testAantal) # it picks 20 random from the test data
    #print(rndWaarde)
    ff=np.argmax(predictions[rndWaarde])#and this finds the most likely
    #print(types[ff])
    img=x_test[rndWaarde]
    if ff == y_test[rndWaarde]:
        fig.add_subplot(rows, columns, i, title=types[ff], xticks=[], yticks=[])
    else:
        fig.add_subplot(rows, columns, i, title=types[ff], xticks=[], yticks=[], xlabel='WRONG!')
        wrong+=1
    plt.imshow(img)
plt.show()
print(str(wrong)+' out of '+str(columns*rows)+' images are predicted wrongly ('+str(wrong/(columns*rows)*100)+'%)')
