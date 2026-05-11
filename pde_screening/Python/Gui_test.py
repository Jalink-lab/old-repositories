import sys
from PyQt5.QtWidgets import QApplication, QWidget, QMainWindow, QFileDialog, QDoubleSpinBox, QPushButton,QAction, QLabel, QTextEdit,QLineEdit, QGridLayout
from PyQt5.QtGui import QIcon
from PyQt5 import QtCore, QtSvg
import os
import pandas as pd
import seaborn as sns
from matplotlib import pyplot
import math
from shutil import copyfile

class MyPdeAnalysis(QMainWindow):
    def __init__(self):    #inherits all methods from QMainWindow
        super().__init__() #initialize QMainWindow
        self.currentWorkingDir = os.getcwd()
        self.initUI()      #initialize MyPdeAnalysis
        
    def initUI(self):
        menubar = self.menuBar()
        fileMenu = menubar.addMenu('File')
        impAct = QAction('Input Directory', self) 
        impAct.triggered.connect(self.openInDirectoryDialog)
        impAct.setShortcut('Ctrl+O')
        fileMenu.addAction(impAct)
        runAct = QAction('Run Analysis', self) 
        runAct.triggered.connect(self.runAnalysis)
        runAct.setShortcut('Ctrl+R')
        fileMenu.addAction(runAct)
        
        inDirBut= QPushButton('Input Directory',self)
        inDirBut.clicked.connect(self.openInDirectoryDialog)
        
        screenLayoutLab = QLabel('ScreenLayout')
        plotTitleLbl = QLabel('Title')
        plotXmaxLbl = QLabel('x-axis maximum')
        
        self.messageBox = QLabel('')
        self.inDirLab = QLabel("")
        self.outDirLab= QLabel("")
        self.screenLayoutEdit = QTextEdit()
        self.plotTitleEdt = QLineEdit()
        self.plotXmaxEdt = QDoubleSpinBox()
        
        #load settings
        settings = QtCore.QSettings('NKI', 'PDE_Analysis_GUI')
        self.inputDirectory = settings.value('inputDirectory', "", str)
        if self.inputDirectory:
            self.inDirLab.setText(str(self.inputDirectory))
            self.setScreenLayout()
        self.plotTitleEdt.setText(settings.value('plotTitle',"",str))
        self.plotXmaxEdt.setValue(settings.value('xmax',0,float))
        
        runButton = QPushButton('Run Analysis', self)
        runButton.setToolTip('Kees loves results!')
        runButton.resize(runButton.sizeHint())   
        runButton.clicked.connect(self.runAnalysis)
        
        grid = QGridLayout()
        grid.setSpacing(10)

        grid.addWidget(inDirBut, 1, 0, 1, 1) #row, column, rowspan, columnspan
        grid.addWidget(self.inDirLab, 1, 1, 1, 3)
        
        grid.addWidget(plotTitleLbl, 2, 0, 1, 1)
        grid.addWidget(self.plotTitleEdt, 2, 1, 1, 1)
        grid.addWidget(plotXmaxLbl, 2, 2, 1, 1)
        grid.addWidget(self.plotXmaxEdt, 2, 3, 1, 1)

        grid.addWidget(screenLayoutLab, 3, 0, 1, 1) 
        grid.addWidget(self.screenLayoutEdit, 3, 1, 5, 3)
        
        grid.addWidget(runButton,8,1)
        grid.addWidget(self.messageBox,9,0,1,4)
        
        centralWidget = QWidget()
        centralWidget.setLayout(grid) 
        
        self.setCentralWidget(centralWidget)
        self.setGeometry(300, 300, 700, 600)
        
        self.setWindowIcon(QIcon('topIcon.svg'))
        self.setWindowTitle('PDE Analysis GUI') 
        self.show()
        
    def openInDirectoryDialog(self): #select a directory and save it to MyPdeAnalysis
        self.inputDirectory = QFileDialog.getExistingDirectory(self, "Select Input Directory")
        #store setting
        settings = QtCore.QSettings('NKI', 'PDE_Analysis_GUI')
        settings.setValue('inputDirectory', self.inputDirectory)
        #set GUI
        self.inDirLab.setText(str(self.inputDirectory))
        self.setScreenLayout()
        
    def setScreenLayout(self):
        self.layout=[]
        txt=''
        try:
            layoutFile = open(os.path.join(self.inputDirectory,'screenLayout.txt'))
            for txt_line in layoutFile:
                txt_line=txt_line.rstrip()
                self.layout.append(txt_line.split(", "))
                txt += txt_line+'\n'
            self.messageBox.setText("Loading layout sucessful!")
        except:
            self.messageBox.setText("ERROR: Could not find "+str(os.path.join(self.inputDirectory,'screenLayout.txt')))
        self.screenLayoutEdit.setText(txt)
        
    def runAnalysis(self):
        if self.layout==[]:
            self.messageBox.setText("ERROR: No layout available")
            return
        #store settings
        settings = QtCore.QSettings('NKI', 'PDE_Analysis_GUI')
        settings.setValue('plotTitle', self.plotTitleEdt.text())
        settings.setValue('xmax',self.plotXmaxEdt.value())
        allData = pd.DataFrame()
        for txt_line in self.layout: #each condition
            for i in range(1,len(txt_line)): #each well
                dataFile = os.path.join(self.inputDirectory,txt_line[i]+'_fitresults.tsv')
                data=pd.read_csv(dataFile,sep='\t')
                data['condition']=txt_line[0].replace('_',' ').replace('uM','μM')
                data.loc[:,'rate(s)'] *= math.log(2)
                data=data.rename(columns={'rate(s)':'half-time(s)'})
                allData=pd.concat([allData,data])
        figsize = (10,8)
        fig, ax = pyplot.subplots(figsize=figsize)
        sns.stripplot(ax=ax, x="half-time(s)", y="condition", data=allData, size=2,zorder=0)
        bbox_props = dict(alpha=0.5)
        sns.boxplot(ax=ax, x="half-time(s)", y="condition", boxprops=bbox_props, data=allData, showfliers=False,zorder=1)
        ax.set_xlim(0,self.plotXmaxEdt.value())
        ax.set_title(self.plotTitleEdt.text())
        fig.savefig(os.path.join(self.currentWorkingDir,'output.svg')) #either a dialog or increment, not overwrite.
        self.messageBox.setText("Result of "+str(len(allData.index))+" cells is in "+self.currentWorkingDir)
        #make a nice viewer for our svg
        window = QMainWindow()
        menu_bar = window.menuBar()
        file_menu = menu_bar.addMenu('File')
        save_action = QAction('Save', window)
        save_action.triggered.connect(self.saveSvg)
        save_action.setShortcut('Ctrl+S')
        file_menu.addAction(save_action)
        exit_action = QAction('Exit', window)
        exit_action.triggered.connect(window.close)
        file_menu.addAction(exit_action)
        svgWidget = QtSvg.QSvgWidget(os.path.join(self.currentWorkingDir,'output.svg'))
        window.setCentralWidget(svgWidget)
        window.setWindowTitle('Result') 
        window.setWindowIcon(QIcon('topIcon.svg'))
        self.window = window
        self.window.show()
        
    def saveSvg(self):
        outputDirectory = QFileDialog.getSaveFileName(self, caption="Save File",directory=self.currentWorkingDir,filter="*.svg")
        if outputDirectory[0]:
            copyfile(os.path.join(self.currentWorkingDir,'output.svg'), outputDirectory[0])

if __name__ == '__main__':
    app = QApplication(sys.argv)
    ex = MyPdeAnalysis()
    app.exec_()