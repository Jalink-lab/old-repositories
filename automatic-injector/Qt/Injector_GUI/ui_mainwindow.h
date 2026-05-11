/********************************************************************************
** Form generated from reading UI file 'mainwindow.ui'
**
** Created by: Qt User Interface Compiler version 5.12.5
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_MAINWINDOW_H
#define UI_MAINWINDOW_H

#include <QtCore/QVariant>
#include <QtWidgets/QAction>
#include <QtWidgets/QApplication>
#include <QtWidgets/QDoubleSpinBox>
#include <QtWidgets/QGridLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMenu>
#include <QtWidgets/QMenuBar>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QStatusBar>
#include <QtWidgets/QToolBar>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_MainWindow
{
public:
    QAction *actionAbout;
    QAction *actionAboutQt;
    QAction *actionConnect;
    QAction *actionDisconnect;
    QAction *actionConfigure;
    QAction *actionClear;
    QAction *actionQuit;
    QAction *actionConfigureInjector;
    QAction *actionConsole;
    QWidget *centralWidget;
    QVBoxLayout *verticalLayout;
    QGridLayout *gridLayout;
    QPushButton *inj1Button;
    QLabel *inj2Label;
    QLabel *inj2ImageLabel;
    QLabel *inj1Label;
    QLabel *inj3ImageLabel;
    QLabel *inj1ImageLabel;
    QPushButton *inj3Button;
    QLabel *inj3Label;
    QPushButton *inj2Button;
    QLabel *label;
    QDoubleSpinBox *inj1Volume;
    QDoubleSpinBox *inj2Volume;
    QDoubleSpinBox *inj3Volume;
    QMenuBar *menuBar;
    QMenu *menuCalls;
    QMenu *menuTools;
    QMenu *menuHelp;
    QToolBar *mainToolBar;
    QStatusBar *statusBar;

    void setupUi(QMainWindow *MainWindow)
    {
        if (MainWindow->objectName().isEmpty())
            MainWindow->setObjectName(QString::fromUtf8("MainWindow"));
        MainWindow->setEnabled(true);
        MainWindow->resize(286, 372);
        actionAbout = new QAction(MainWindow);
        actionAbout->setObjectName(QString::fromUtf8("actionAbout"));
        actionAboutQt = new QAction(MainWindow);
        actionAboutQt->setObjectName(QString::fromUtf8("actionAboutQt"));
        actionConnect = new QAction(MainWindow);
        actionConnect->setObjectName(QString::fromUtf8("actionConnect"));
        QIcon icon;
        icon.addFile(QString::fromUtf8(":/images/connect.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionConnect->setIcon(icon);
        actionDisconnect = new QAction(MainWindow);
        actionDisconnect->setObjectName(QString::fromUtf8("actionDisconnect"));
        QIcon icon1;
        icon1.addFile(QString::fromUtf8(":/images/disconnect.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionDisconnect->setIcon(icon1);
        actionConfigure = new QAction(MainWindow);
        actionConfigure->setObjectName(QString::fromUtf8("actionConfigure"));
        QIcon icon2;
        icon2.addFile(QString::fromUtf8(":/images/settings.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionConfigure->setIcon(icon2);
        actionClear = new QAction(MainWindow);
        actionClear->setObjectName(QString::fromUtf8("actionClear"));
        QIcon icon3;
        icon3.addFile(QString::fromUtf8(":/images/clear.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionClear->setIcon(icon3);
        actionQuit = new QAction(MainWindow);
        actionQuit->setObjectName(QString::fromUtf8("actionQuit"));
        QIcon icon4;
        icon4.addFile(QString::fromUtf8(":/images/application-exit.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionQuit->setIcon(icon4);
        actionConfigureInjector = new QAction(MainWindow);
        actionConfigureInjector->setObjectName(QString::fromUtf8("actionConfigureInjector"));
        QIcon icon5;
        icon5.addFile(QString::fromUtf8(":/images/settings_inj.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionConfigureInjector->setIcon(icon5);
        actionConsole = new QAction(MainWindow);
        actionConsole->setObjectName(QString::fromUtf8("actionConsole"));
        QIcon icon6;
        icon6.addFile(QString::fromUtf8(":/images/console.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionConsole->setIcon(icon6);
        centralWidget = new QWidget(MainWindow);
        centralWidget->setObjectName(QString::fromUtf8("centralWidget"));
        verticalLayout = new QVBoxLayout(centralWidget);
        verticalLayout->setSpacing(6);
        verticalLayout->setContentsMargins(11, 11, 11, 11);
        verticalLayout->setObjectName(QString::fromUtf8("verticalLayout"));
        gridLayout = new QGridLayout();
        gridLayout->setSpacing(6);
        gridLayout->setObjectName(QString::fromUtf8("gridLayout"));
        inj1Button = new QPushButton(centralWidget);
        inj1Button->setObjectName(QString::fromUtf8("inj1Button"));
        inj1Button->setEnabled(false);
        inj1Button->setCheckable(true);

        gridLayout->addWidget(inj1Button, 2, 1, 1, 1);

        inj2Label = new QLabel(centralWidget);
        inj2Label->setObjectName(QString::fromUtf8("inj2Label"));
        inj2Label->setAlignment(Qt::AlignCenter);

        gridLayout->addWidget(inj2Label, 0, 2, 1, 1);

        inj2ImageLabel = new QLabel(centralWidget);
        inj2ImageLabel->setObjectName(QString::fromUtf8("inj2ImageLabel"));
        inj2ImageLabel->setPixmap(QPixmap(QString::fromUtf8(":/images/injector_empty.png")));
        inj2ImageLabel->setAlignment(Qt::AlignCenter);

        gridLayout->addWidget(inj2ImageLabel, 1, 2, 1, 1);

        inj1Label = new QLabel(centralWidget);
        inj1Label->setObjectName(QString::fromUtf8("inj1Label"));
        inj1Label->setAlignment(Qt::AlignCenter);

        gridLayout->addWidget(inj1Label, 0, 1, 1, 1);

        inj3ImageLabel = new QLabel(centralWidget);
        inj3ImageLabel->setObjectName(QString::fromUtf8("inj3ImageLabel"));
        inj3ImageLabel->setPixmap(QPixmap(QString::fromUtf8(":/images/injector_empty.png")));
        inj3ImageLabel->setAlignment(Qt::AlignCenter);

        gridLayout->addWidget(inj3ImageLabel, 1, 3, 1, 1);

        inj1ImageLabel = new QLabel(centralWidget);
        inj1ImageLabel->setObjectName(QString::fromUtf8("inj1ImageLabel"));
        inj1ImageLabel->setPixmap(QPixmap(QString::fromUtf8(":/images/injector_empty.png")));
        inj1ImageLabel->setAlignment(Qt::AlignCenter);

        gridLayout->addWidget(inj1ImageLabel, 1, 1, 1, 1);

        inj3Button = new QPushButton(centralWidget);
        inj3Button->setObjectName(QString::fromUtf8("inj3Button"));
        inj3Button->setEnabled(false);
        inj3Button->setCheckable(true);
        inj3Button->setChecked(false);

        gridLayout->addWidget(inj3Button, 2, 3, 1, 1);

        inj3Label = new QLabel(centralWidget);
        inj3Label->setObjectName(QString::fromUtf8("inj3Label"));
        inj3Label->setAlignment(Qt::AlignCenter);

        gridLayout->addWidget(inj3Label, 0, 3, 1, 1);

        inj2Button = new QPushButton(centralWidget);
        inj2Button->setObjectName(QString::fromUtf8("inj2Button"));
        inj2Button->setEnabled(false);
        inj2Button->setCheckable(true);
        inj2Button->setChecked(false);

        gridLayout->addWidget(inj2Button, 2, 2, 1, 1);

        label = new QLabel(centralWidget);
        label->setObjectName(QString::fromUtf8("label"));

        gridLayout->addWidget(label, 3, 0, 1, 1);

        inj1Volume = new QDoubleSpinBox(centralWidget);
        inj1Volume->setObjectName(QString::fromUtf8("inj1Volume"));
        inj1Volume->setAlignment(Qt::AlignCenter);
        inj1Volume->setMaximum(10.000000000000000);
        inj1Volume->setSingleStep(0.100000000000000);
        inj1Volume->setValue(1.000000000000000);

        gridLayout->addWidget(inj1Volume, 3, 1, 1, 1);

        inj2Volume = new QDoubleSpinBox(centralWidget);
        inj2Volume->setObjectName(QString::fromUtf8("inj2Volume"));
        inj2Volume->setAlignment(Qt::AlignCenter);
        inj2Volume->setMaximum(10.000000000000000);
        inj2Volume->setSingleStep(0.100000000000000);
        inj2Volume->setValue(1.000000000000000);

        gridLayout->addWidget(inj2Volume, 3, 2, 1, 1);

        inj3Volume = new QDoubleSpinBox(centralWidget);
        inj3Volume->setObjectName(QString::fromUtf8("inj3Volume"));
        inj3Volume->setEnabled(true);
        inj3Volume->setAlignment(Qt::AlignCenter);
        inj3Volume->setMaximum(10.000000000000000);
        inj3Volume->setSingleStep(0.100000000000000);
        inj3Volume->setValue(1.000000000000000);

        gridLayout->addWidget(inj3Volume, 3, 3, 1, 1);


        verticalLayout->addLayout(gridLayout);

        MainWindow->setCentralWidget(centralWidget);
        menuBar = new QMenuBar(MainWindow);
        menuBar->setObjectName(QString::fromUtf8("menuBar"));
        menuBar->setGeometry(QRect(0, 0, 286, 17));
        menuCalls = new QMenu(menuBar);
        menuCalls->setObjectName(QString::fromUtf8("menuCalls"));
        menuTools = new QMenu(menuBar);
        menuTools->setObjectName(QString::fromUtf8("menuTools"));
        menuHelp = new QMenu(menuBar);
        menuHelp->setObjectName(QString::fromUtf8("menuHelp"));
        MainWindow->setMenuBar(menuBar);
        mainToolBar = new QToolBar(MainWindow);
        mainToolBar->setObjectName(QString::fromUtf8("mainToolBar"));
        MainWindow->addToolBar(Qt::TopToolBarArea, mainToolBar);
        statusBar = new QStatusBar(MainWindow);
        statusBar->setObjectName(QString::fromUtf8("statusBar"));
        MainWindow->setStatusBar(statusBar);

        menuBar->addAction(menuCalls->menuAction());
        menuBar->addAction(menuTools->menuAction());
        menuBar->addAction(menuHelp->menuAction());
        menuCalls->addAction(actionConnect);
        menuCalls->addAction(actionDisconnect);
        menuCalls->addSeparator();
        menuCalls->addAction(actionQuit);
        menuTools->addAction(actionConfigure);
        menuTools->addAction(actionClear);
        menuTools->addAction(actionConfigureInjector);
        menuTools->addAction(actionConsole);
        menuHelp->addAction(actionAbout);
        menuHelp->addAction(actionAboutQt);
        mainToolBar->addAction(actionConnect);
        mainToolBar->addAction(actionDisconnect);
        mainToolBar->addAction(actionConfigure);
        mainToolBar->addAction(actionConfigureInjector);
        mainToolBar->addAction(actionConsole);

        retranslateUi(MainWindow);

        QMetaObject::connectSlotsByName(MainWindow);
    } // setupUi

    void retranslateUi(QMainWindow *MainWindow)
    {
        MainWindow->setWindowTitle(QApplication::translate("MainWindow", "JalinkLab Injector", nullptr));
        actionAbout->setText(QApplication::translate("MainWindow", "&About", nullptr));
#ifndef QT_NO_TOOLTIP
        actionAbout->setToolTip(QApplication::translate("MainWindow", "About program", nullptr));
#endif // QT_NO_TOOLTIP
#ifndef QT_NO_SHORTCUT
        actionAbout->setShortcut(QApplication::translate("MainWindow", "Alt+A", nullptr));
#endif // QT_NO_SHORTCUT
        actionAboutQt->setText(QApplication::translate("MainWindow", "About Qt", nullptr));
        actionConnect->setText(QApplication::translate("MainWindow", "C&onnect", nullptr));
#ifndef QT_NO_TOOLTIP
        actionConnect->setToolTip(QApplication::translate("MainWindow", "Connect to serial port", nullptr));
#endif // QT_NO_TOOLTIP
#ifndef QT_NO_SHORTCUT
        actionConnect->setShortcut(QApplication::translate("MainWindow", "Ctrl+O", nullptr));
#endif // QT_NO_SHORTCUT
        actionDisconnect->setText(QApplication::translate("MainWindow", "&Disconnect", nullptr));
#ifndef QT_NO_TOOLTIP
        actionDisconnect->setToolTip(QApplication::translate("MainWindow", "Disconnect from serial port", nullptr));
#endif // QT_NO_TOOLTIP
#ifndef QT_NO_SHORTCUT
        actionDisconnect->setShortcut(QApplication::translate("MainWindow", "Ctrl+D", nullptr));
#endif // QT_NO_SHORTCUT
        actionConfigure->setText(QApplication::translate("MainWindow", "&Configure Serial Port", nullptr));
#ifndef QT_NO_TOOLTIP
        actionConfigure->setToolTip(QApplication::translate("MainWindow", "Configure serial port", nullptr));
#endif // QT_NO_TOOLTIP
#ifndef QT_NO_SHORTCUT
        actionConfigure->setShortcut(QApplication::translate("MainWindow", "Alt+C", nullptr));
#endif // QT_NO_SHORTCUT
        actionClear->setText(QApplication::translate("MainWindow", "C&lear Monitor", nullptr));
#ifndef QT_NO_TOOLTIP
        actionClear->setToolTip(QApplication::translate("MainWindow", "Clear data", nullptr));
#endif // QT_NO_TOOLTIP
#ifndef QT_NO_SHORTCUT
        actionClear->setShortcut(QApplication::translate("MainWindow", "Alt+L", nullptr));
#endif // QT_NO_SHORTCUT
        actionQuit->setText(QApplication::translate("MainWindow", "&Quit", nullptr));
#ifndef QT_NO_SHORTCUT
        actionQuit->setShortcut(QApplication::translate("MainWindow", "Ctrl+Q", nullptr));
#endif // QT_NO_SHORTCUT
        actionConfigureInjector->setText(QApplication::translate("MainWindow", "C&onfigure Injector", nullptr));
#ifndef QT_NO_SHORTCUT
        actionConfigureInjector->setShortcut(QApplication::translate("MainWindow", "Ctrl+Alt+I", nullptr));
#endif // QT_NO_SHORTCUT
        actionConsole->setText(QApplication::translate("MainWindow", "Console", nullptr));
        inj1Button->setText(QApplication::translate("MainWindow", "Take-Up", nullptr));
        inj2Label->setText(QApplication::translate("MainWindow", "IBMX", nullptr));
        inj2ImageLabel->setText(QString());
        inj1Label->setText(QApplication::translate("MainWindow", "Forskolin", nullptr));
        inj3ImageLabel->setText(QString());
        inj1ImageLabel->setText(QString());
        inj3Button->setText(QApplication::translate("MainWindow", "Take-Up", nullptr));
        inj3Label->setText(QApplication::translate("MainWindow", "IsoProterenol", nullptr));
        inj2Button->setText(QApplication::translate("MainWindow", "Take-Up", nullptr));
        label->setText(QApplication::translate("MainWindow", "V(\316\274L)", nullptr));
        menuCalls->setTitle(QApplication::translate("MainWindow", "File", nullptr));
        menuTools->setTitle(QApplication::translate("MainWindow", "Tools", nullptr));
        menuHelp->setTitle(QApplication::translate("MainWindow", "Help", nullptr));
    } // retranslateUi

};

namespace Ui {
    class MainWindow: public Ui_MainWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINWINDOW_H
