QT += widgets serialport
requires(qtConfig(combobox))

TARGET = JL_Injector
TEMPLATE = app

SOURCES += \
    main.cpp \
    mainwindow.cpp \
    settingsdialog.cpp \
    console.cpp \
    settingsinjectordialog.cpp

HEADERS += \
    mainwindow.h \
    settingsdialog.h \
    console.h \
    settingsinjectordialog.h

FORMS += \
    mainwindow.ui \
    settingsdialog.ui \
    settingsinjectordialog.ui

RESOURCES += \
    injector.qrc

RC_FILE = injector.rc

target.path = E:/GitHub_Reps/Injector_GUI
INSTALLS += target
