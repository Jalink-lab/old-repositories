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
from random import seed
from random import randint
## seed random number generator
#seed(1)
#%matplotlib inline

mnist=tf.keras.datasets.mnist
(x_train, y_train),(x_test, y_test) = mnist.load_data()
#print(x_train[0])
#plt.imshow(x_train[0],cmap=plt.cm.binary)
#plt.show()
#print(y_train[0])

#now lets do data normalization
x_train = tf.keras.utils.normalize(x_train, axis=1)
x_test = tf.keras.utils.normalize(x_test, axis=1)
#next, we finally start to build the model
model = tf.keras.models.Sequential()
#now different from what I did 30 years ago, they make it flat, not 2D
#that makes it simpler with indices and should not make ANY difference
model.add(tf.keras.layers.Flatten()) #flat input layer
model.add(tf.keras.layers.Dense(128, activation=tf.nn.relu))
model.add(tf.keras.layers.Dense(128, activation=tf.nn.relu)) #added 2 relay layers
model.add(tf.keras.layers.Dense(10, activation=tf.nn.softmax))
#and an output layer which is 10 big: numbers 0-9
model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])

#model.fit(x_train, y_train, epochs=10)
#history = model.fit(x_train, y_train, epochs=25, validation_split=0.2, steps_per_epoch=100) #faster
history = model.fit(x_train, y_train, epochs=10, validation_split=0.2)

# Plot training & validation accuracy values
plt.plot(history.history['accuracy'])
plt.plot(history.history['val_accuracy'])
plt.title('Model accuracy')
plt.ylabel('Accuracy')
plt.xlabel('Epoch')
plt.legend(['Train', 'Validation'], loc='upper left')
plt.show()

# Plot training & validation loss values
plt.plot(history.history['loss'])
plt.plot(history.history['val_loss'])
plt.title('Model loss')
plt.ylabel('Loss')
plt.xlabel('Epoch')
plt.legend(['Train', 'Validation'], loc='upper left')
plt.show()


#next lets run that on the verification datasets x_test and y_test
val_loss, val_acc = model.evaluate(x_test, y_test)
print(val_loss)
print(val_acc)

model.save('c:\dataff\epic_num_reader.model')
#Load it back:
new_model = tf.keras.models.load_model('c:\dataff\epic_num_reader.model')
predictions = new_model.predict(x_test)
#print(predictions)# these are the probablities that the pic is each of 0-9


#for plaatje in range(1,20):
#    rndWaarde=randint(1,10000)
#    print(np.argmax(predictions[rndWaarde])) #and this finds the most likely
#    plt.imshow(x_test[rndWaarde],cmap=plt.cm.binary)
#    plt.show()


columns = 8
rows = 4
fig=plt.figure(figsize=(columns*2, rows*2.4))


wrong = 0
for i in range(1, columns*rows +1):
    rndWaarde=randint(1,10000)
    #print(rndWaarde)
    predictedNumber=np.argmax(predictions[rndWaarde])#and this finds the most likely
    #print(types[ff])
    img=x_test[rndWaarde]
    if predictedNumber == y_test[rndWaarde]:
        fig.add_subplot(rows, columns, i, title=predictedNumber, xticks=[], yticks=[])
    else:
        fig.add_subplot(rows, columns, i, title=predictedNumber, xticks=[], yticks=[], xlabel='WRONG!')
        wrong+=1
    plt.imshow(img)
plt.show()
print(str(wrong)+' out of '+str(columns*rows)+' images are predicted wrongly ('+str(wrong/(columns*rows)*100)+'%)')

