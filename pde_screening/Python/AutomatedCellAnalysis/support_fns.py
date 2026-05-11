# -*- coding: utf-8 -*-
"""
Created on Fri Nov 13 14:28:28 2020
Support functions to the pde screening analysis toolset
@author: keesj
"""
import shutil
from pathlib import Path
from AutomatedCellAnalysis.config import Config
from tkinter import filedialog
from datetime import datetime

def delete_old_results(foldername, replace=False): #Fn: delete old files/folders if the user instructs so
    if foldername.exists():
        if replace==True:
            shutil.rmtree(foldername) #be exceptionally careful with rmtree. It deletes entire folders or trees
            print("results folder "+str(foldername)+" has been deleted")
            
def remember_setting(what_to_remember, mem_default, quote_string, ask_for_update):   #remember the last folder/file in your home directory in a config file 'jalink_pde_config.ini'
    cfg=Config( ) #uses Rolfs json script to write configuration file
    what_to_remember = cfg.readorwrite(what_to_remember, mem_default) #this reads/writes by default in \users\username folder
    #if the file exists and has a key myPath it is read into variable myPath, else the file is made and set to mem_default
    mem_output=what_to_remember
    if ask_for_update==True:
        mem_output = filedialog.askdirectory(title=quote_string, initialdir=what_to_remember, mustexist=True)
        cfg.write(what_to_remember, mem_output)
    return mem_output

def replace_or_backup_old_results(foldername, switch): #switch is A (replace All), R (Replace old fit results) or BUname
    if foldername.exists()==False:
        print(str(foldername)+ " does not exist!! Terminating.")
        return
    if switch.upper()=="R" or switch.upper()=="": #when switch is empty, Replace is default
        delete_old_results(foldername, True)
    elif switch[0:2].upper()=="BU":
        new_path=Path(str(foldername)+switch)
        while new_path.exists(): #make sure the new name is not existing yet
            new_path=Path(str(new_path)+"X")
            print("that name existed already; added X to path")
        foldername.rename(new_path)
    else:
        pass  #else the choice was A, which has been taken care of.
   
def get_data_replacement_choice(): #returns 3 possible outcome for any input: R, A or BUname
    choice = filedialog.simpledialog.askstring("How to handle old analysis results?",
           prompt="Clear all analysis results (C); Replace only fit results (R) or BackUp fit results (enter BU#; e.g. BU02") #this is a intermediate solution, lets rather use raw data containing the correct metadata!
    if choice.upper()=="C":
        choice="C"
    elif choice.upper()=="R":
        choice="R"
    elif choice[0:2].upper()=="BU":
        if choice.isalnum():
            choice="BU" + choice[2:]
        else:
            choice="BU"+str(datetime.now())[-6:]
            print("Warning. invalid BackUp name has been replaced by "+ choice)
    else:
        print("WARNING: data replacement selection invalid. Using default choice: R")
        choice="R"
    return choice



