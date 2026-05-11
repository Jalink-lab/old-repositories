"""
Split off just displaydata
"""
import seaborn as sns
import matplotlib.pyplot as plt


def displaydata(all_data, x_val, debug=False):
    """
    display all_data in a stripplot with boxplot overlay
    :param debug:
    :param all_data:
    """
    # get a figure (top level) and an axis (sub level) at the same time
    # get a figure (top level) and an axis (sub level) at the same time
    fig, ax = plt.subplots()
    sns.stripplot(ax=ax, x=x_val, y="condition", data=all_data, size=2, zorder=0)
    bbox_props = dict(alpha=0.5, )
    sns.boxplot(ax=ax, x=x_val, y="condition", boxprops=bbox_props,
                data=all_data, showmeans=True,
                meanprops={"linestyle":":", "linewidth":"2", "color":"green"}, meanline=True,
                showfliers=False, zorder=1)
    ax2 = ax.twinx()
    ax2.yaxis.set_label_position("right")
    ax2.set_ylabel("Number of Cells")
    # generate ticks with the nr of cells
    allconditions = all_data.condition.unique()
    if debug:
        print("got {0} conditions".format(len(allconditions)))
    # yaxis runs from 0 to 1 if there would be 10 conditions they would be at 0.05 0.15 .. 0.85 0.95
    ticks = [1 / (2 * (len(allconditions)))]
    for i in range(0, len(allconditions) - 1):
        ticks.append(ticks[i] + 1 / (len(allconditions)))
    ax2.set_yticks(ticks)
    if debug:
        print("got {0} ticks".format(len(ticks)))
    yticklabels = []
    for condition in allconditions:
        yticklabels.append(str(sum(all_data['condition'] == condition)))
    ax2.set_yticklabels(reversed(yticklabels))
    if debug:
        print("got {0} ticklabels".format(1+len(yticklabels)))
    return fig, ax
