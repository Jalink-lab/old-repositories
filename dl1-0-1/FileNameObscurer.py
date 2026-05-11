# -*- coding: utf-8 -*-
"""
Created on Tue May  5 21:31:39 2020
Python File Obscurer. Works by renaming files in a predictable manner in the 
entire foldertree. Run it again to revert to the original
@author: keesj
"""

import os


def spiegel(text):
    #simple example of a file name encoding; replace by your own secret encryption
    text=text[::-1] #mirrors all characters in the filename and extension
    return text


rootDirFolder=("C:\\dataff") #the inevitable KJ-example
for path, subdirs, files in os.walk(rootDirFolder):
    for name in files:
        file_path = os.path.join(path,name)
        print(file_path) 
        print("next")
        # omgekeerd=spiegel(name)
        # new_name = os.path.join(path,omgekeerd)
        # os.rename(file_path, new_name)       
        # print(os.path.join(new_name))



