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

path='C:/dataff/x_train' #load images
x_train=np.fromfile(path, dtype=np.uint8).reshape(trainAantal,grootte,grootte)
#plt.imshow(x_train[3,:,:])
path='C:/dataff/x_test'
x_test=np.fromfile(path, dtype=np.uint8).reshape(testAantal,grootte,grootte)
#plt.imshow(x_test[3,:,:])

path='C:/dataff/y_train.txt' #load classifiers
y_train= np.loadtxt(path, dtype=np.uint8, delimiter='\t')
path='C:/dataff/y_test.txt'
y_test= np.loadtxt(path, dtype=np.uint8, delimiter='\t')
#====================================ends

#now lets do data normalization. not strikt necessary but should make less color-dependent
x_train_norm =tf.keras.utils.normalize(x_train, axis=1)
x_test_norm = tf.keras.utils.normalize(x_test, axis=1)

#next, we finally start to build the model
model = tf.keras.models.Sequential()
#now different from what I did 30 years ago, they make it flat, not 2D
#that makes it simpler with indices and should not make ANY difference
#and I did a stupid thing with color
model.add(tf.keras.layers.Flatten()) #flat input layer
model.add(tf.keras.layers.Dense(128, activation=tf.nn.relu)) #added 2 relay layers
model.add(tf.keras.layers.Dense(128, activation=tf.nn.relu)) 
model.add(tf.keras.layers.Dense(7, activation=tf.nn.softmax)) 
model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])

#---- probeersels Bram ----
#tf.keras.optimizers.SGD(learning_rate=0.05, momentum=0.0, nesterov=False)
#model.compile(optimizer='sgd', loss='sparse_categorical_crossentropy', metrics=['accuracy'])

#history = model.fit(x_train_norm, y_train, epochs=50, validation_split=0.2) #this is the calculation statement
history = model.fit(x_train_norm, y_train, epochs=10, validation_split=0.2, steps_per_epoch=100) #very fast, for testing

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
val_loss, val_acc = model.evaluate(x_test_norm, y_test)
print(val_loss)
print(val_acc)

model.save('c:\dataff\kjImagesModel') 
#Load it back:

new_model = tf.keras.models.load_model('c:\dataff\kjImagesModel')
predictions = new_model.predict(x_test_norm)
#print(predictions)# these are the probablities that the pic is each of 0-9

types={1: "closed round", 2: "closed square", 3: "closed triangle", 4: "open circle", 5:"open box", 6:"open triangle" }


columns = 8
rows = 4
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




