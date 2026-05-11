"""
Analysis
"""
import os
import pandas as pd
import seaborn as sns
from matplotlib import pyplot
import math


class MyScreeningAnalysis:
    """
    Screening analysis for PDE screen
    """
    def __init__(self, inpth, outpth, title):
        self.inpth = inpth
        self.outpth = outpth
        self.title = title

    def run(self):
        """
        run the analysis
        """
        # load the layout file
        layout_file = open(os.path.join(self.inpth, 'screenLayout.txt'))
        layout = []
        for txt_line in layout_file:
            txt_line = txt_line.rstrip()  # remove all spaces and returns at the end of the line
            layout.append(txt_line.split(", "))
        all_data = pd.DataFrame()
        for txt_line in layout:  # each condition
            for i in range(1, len(txt_line)):  # each well
                data_file = os.path.join(self.inpth, txt_line[i] + '_fitresults.tsv')
                data = pd.read_csv(data_file, sep='\t')
                data['condition'] = txt_line[0].replace('_', ' ').replace('uM', 'μM')
                data.loc[:, 'rate(s)'] *= math.log(2)
                data = data.rename(columns={'rate(s)': 'half-time(s)'})
                all_data = pd.concat([all_data, data])
        figsize = (8, 8)
        fig, ax = pyplot.subplots(figsize=figsize)  # get a figure (top level) and an axis (sub level) at the same time
        sns.stripplot(ax=ax, x="half-time(s)", y="condition", data=all_data, size=2, zorder=0)
        bbox_props = dict(alpha=0.5, )
        sns.boxplot(ax=ax, x="half-time(s)", y="condition", boxprops=bbox_props, data=all_data, showfliers=False,
                    zorder=1)
        ax.set_xlim(0, 60)
        ax.set_title(self.title)
        fig.savefig(os.path.join(self.outpth, 'output.svg'))
        print("result of " + str(len(all_data.index)) + " cells is in " + self.outpth)


root_pth = 'G:\\SurfDrive\\Screening_Data'
my_inpth = os.path.join(root_pth, '2019', '12', '05', 'results')
my_outpth = os.getcwd()
msa = MyScreeningAnalysis(my_inpth, my_outpth, 'myPlot')
msa.run()
os.system("pause")
