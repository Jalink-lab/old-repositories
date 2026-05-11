# -*- coding: utf-8 -*-
"""
Created on Sun Dec  8 14:48:06 2019
see https://pythonprogramming.net/introduction-deep-learning-python-tensorflow-keras/
@author: keesj

RECOGNIZE CIPHERS

"""
import numpy as np
import matplotlib.pyplot as plt
#C:\Users\keesj\Anaconda3\envs\spyder\Scripts

#pip install --upgrade tensorflow  # I guess only needed once
import tensorflow as tf #this has imported tensorflow 2.0
from random import randint
## seed random number generator
#seed(1)
#%matplotlib inline

#mnist=tf.keras.datasets.fashion_mnist
mnist=tf.keras.datasets.mnist
(x_train, y_train),(x_test, y_test) = mnist.load_data()

x_test_norm = tf.keras.utils.normalize(x_test, axis=1)


#Load the model:
new_model = tf.keras.models.load_model('c:\dataff\epic_num_reader.model')
predictions = new_model.predict(x_test_norm)
#print(predictions)# these are the probablities that the pic is each of 0-9


#types={0: "T-shirt/top", 1: "Trouser", 2: "Pullover", 3: "Dress", 4:"Coat", 5:"Sandal", 6:"Shirt", 7:"Sneaker", 8:"Bag", 9:"Ankle boot"}
types={0: "0", 1: "1", 2: "2", 3: "3", 4:"4", 5:"5", 6:"6", 7:"7", 8:"8", 9:"9"}


columns = 8
rows = 4
fig=plt.figure(figsize=(columns*2, rows*2.4))


wrong = 0
for i in range(1, columns*rows +1):
    rndWaarde=randint(1,10000)
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

