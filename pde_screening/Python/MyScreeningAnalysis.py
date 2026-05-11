"""
Old version for loading data from the ImageJ analysis
"""
import os
import math
import pandas as pd

def loaddata(inpth):
    layout_file = open(os.path.join(inpth, 'screenLayout.txt'))
    layout = []
    for txt_line in layout_file:
        txt_line = txt_line.rstrip()  # remove all spaces and returns at the end of the line
        layout.append(txt_line.split(", "))
    all_data = pd.DataFrame()
    for txt_line in layout:  # each condition
        for i in range(1, len(txt_line)):  # each well
            data_file = os.path.join(inpth, txt_line[i] + '_fitresults.tsv')
            data = pd.read_csv(data_file, sep='\t')
            data['condition'] = txt_line[0].replace('_', ' ').replace('uM', 'μM')
            data.loc[:, 'rate(s)'] *= math.log(2)
            data = data.rename(columns={'rate(s)': 'half-time(s)'})
            all_data = pd.concat([all_data, data])
    return all_data

