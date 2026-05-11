/********************************************************************************
** Form generated from reading UI file 'settingsinjectordialog.ui'
**
** Created by: Qt User Interface Compiler version 5.12.5
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_SETTINGSINJECTORDIALOG_H
#define UI_SETTINGSINJECTORDIALOG_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QDialog>
#include <QtWidgets/QDoubleSpinBox>
#include <QtWidgets/QGridLayout>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSpacerItem>
#include <QtWidgets/QSpinBox>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_SettingsInjectorDialog
{
public:
    QWidget *horizontalLayoutWidget;
    QHBoxLayout *horizontalLayout;
    QSpacerItem *horizontalSpacer;
    QPushButton *applyButton;
    QWidget *gridLayoutWidget;
    QGridLayout *SettingsBox;
    QLabel *name_label;
    QDoubleSpinBox *inj2_BubbleVolume;
    QLabel *label;
    QComboBox *inj2_Speed;
    QLabel *inj2_label;
    QLabel *inj1_label;
    QLabel *inj3_label;
    QDoubleSpinBox *inj1_BubbleVolume;
    QLabel *speed_label;
    QLineEdit *inj3_name;
    QSpinBox *inj3PwmUp;
    QSpinBox *inj2PwmDown;
    QSpinBox *inj2PwmUp;
    QSpinBox *inj3PwmDown;
    QDoubleSpinBox *inj2EjectVolume;
    QLineEdit *inj2_name;
    QLabel *label_3;
    QComboBox *inj3_Speed;
    QLabel *label_2;
    QSpinBox *inj1PwmDown;
    QSpinBox *inj1PwmUp;
    QComboBox *inj1_Speed;
    QDoubleSpinBox *inj1EjectVolume;
    QDoubleSpinBox *inj3_BubbleVolume;
    QLabel *ejectV_label;
    QLabel *bubbleV_label;
    QLineEdit *inj1_name;
    QDoubleSpinBox *inj3EjectVolume;
    QDoubleSpinBox *inj1_StepsPerMicroLiter;
    QDoubleSpinBox *inj2_StepsPerMicroLiter;
    QDoubleSpinBox *inj3_StepsPerMicroLiter;

    void setupUi(QDialog *SettingsInjectorDialog)
    {
        if (SettingsInjectorDialog->objectName().isEmpty())
            SettingsInjectorDialog->setObjectName(QString::fromUtf8("SettingsInjectorDialog"));
        SettingsInjectorDialog->resize(548, 274);
        QSizePolicy sizePolicy(QSizePolicy::Preferred, QSizePolicy::Preferred);
        sizePolicy.setHorizontalStretch(0);
        sizePolicy.setVerticalStretch(0);
        sizePolicy.setHeightForWidth(SettingsInjectorDialog->sizePolicy().hasHeightForWidth());
        SettingsInjectorDialog->setSizePolicy(sizePolicy);
        SettingsInjectorDialog->setMinimumSize(QSize(0, 0));
        horizontalLayoutWidget = new QWidget(SettingsInjectorDialog);
        horizontalLayoutWidget->setObjectName(QString::fromUtf8("horizontalLayoutWidget"));
        horizontalLayoutWidget->setGeometry(QRect(20, 230, 521, 31));
        horizontalLayout = new QHBoxLayout(horizontalLayoutWidget);
        horizontalLayout->setObjectName(QString::fromUtf8("horizontalLayout"));
        horizontalLayout->setContentsMargins(0, 0, 0, 0);
        horizontalSpacer = new QSpacerItem(40, 20, QSizePolicy::Expanding, QSizePolicy::Minimum);

        horizontalLayout->addItem(horizontalSpacer);

        applyButton = new QPushButton(horizontalLayoutWidget);
        applyButton->setObjectName(QString::fromUtf8("applyButton"));

        horizontalLayout->addWidget(applyButton);

        gridLayoutWidget = new QWidget(SettingsInjectorDialog);
        gridLayoutWidget->setObjectName(QString::fromUtf8("gridLayoutWidget"));
        gridLayoutWidget->setGeometry(QRect(19, 10, 521, 216));
        SettingsBox = new QGridLayout(gridLayoutWidget);
        SettingsBox->setObjectName(QString::fromUtf8("SettingsBox"));
        SettingsBox->setContentsMargins(0, 0, 0, 0);
        name_label = new QLabel(gridLayoutWidget);
        name_label->setObjectName(QString::fromUtf8("name_label"));

        SettingsBox->addWidget(name_label, 1, 0, 1, 1);

        inj2_BubbleVolume = new QDoubleSpinBox(gridLayoutWidget);
        inj2_BubbleVolume->setObjectName(QString::fromUtf8("inj2_BubbleVolume"));
        inj2_BubbleVolume->setSingleStep(0.100000000000000);
        inj2_BubbleVolume->setValue(0.500000000000000);

        SettingsBox->addWidget(inj2_BubbleVolume, 4, 2, 1, 1);

        label = new QLabel(gridLayoutWidget);
        label->setObjectName(QString::fromUtf8("label"));

        SettingsBox->addWidget(label, 6, 0, 1, 1);

        inj2_Speed = new QComboBox(gridLayoutWidget);
        inj2_Speed->addItem(QString());
        inj2_Speed->addItem(QString());
        inj2_Speed->addItem(QString());
        inj2_Speed->addItem(QString());
        inj2_Speed->addItem(QString());
        inj2_Speed->setObjectName(QString::fromUtf8("inj2_Speed"));

        SettingsBox->addWidget(inj2_Speed, 2, 2, 1, 1);

        inj2_label = new QLabel(gridLayoutWidget);
        inj2_label->setObjectName(QString::fromUtf8("inj2_label"));

        SettingsBox->addWidget(inj2_label, 0, 2, 1, 1);

        inj1_label = new QLabel(gridLayoutWidget);
        inj1_label->setObjectName(QString::fromUtf8("inj1_label"));

        SettingsBox->addWidget(inj1_label, 0, 1, 1, 1);

        inj3_label = new QLabel(gridLayoutWidget);
        inj3_label->setObjectName(QString::fromUtf8("inj3_label"));

        SettingsBox->addWidget(inj3_label, 0, 3, 1, 1);

        inj1_BubbleVolume = new QDoubleSpinBox(gridLayoutWidget);
        inj1_BubbleVolume->setObjectName(QString::fromUtf8("inj1_BubbleVolume"));
        inj1_BubbleVolume->setMaximum(10.000000000000000);
        inj1_BubbleVolume->setSingleStep(0.100000000000000);
        inj1_BubbleVolume->setValue(0.500000000000000);

        SettingsBox->addWidget(inj1_BubbleVolume, 4, 1, 1, 1);

        speed_label = new QLabel(gridLayoutWidget);
        speed_label->setObjectName(QString::fromUtf8("speed_label"));

        SettingsBox->addWidget(speed_label, 2, 0, 1, 1);

        inj3_name = new QLineEdit(gridLayoutWidget);
        inj3_name->setObjectName(QString::fromUtf8("inj3_name"));

        SettingsBox->addWidget(inj3_name, 1, 3, 1, 1);

        inj3PwmUp = new QSpinBox(gridLayoutWidget);
        inj3PwmUp->setObjectName(QString::fromUtf8("inj3PwmUp"));
        inj3PwmUp->setMaximum(2000);
        inj3PwmUp->setValue(1000);

        SettingsBox->addWidget(inj3PwmUp, 6, 3, 1, 1);

        inj2PwmDown = new QSpinBox(gridLayoutWidget);
        inj2PwmDown->setObjectName(QString::fromUtf8("inj2PwmDown"));
        inj2PwmDown->setMaximum(2000);
        inj2PwmDown->setValue(1800);

        SettingsBox->addWidget(inj2PwmDown, 7, 2, 1, 1);

        inj2PwmUp = new QSpinBox(gridLayoutWidget);
        inj2PwmUp->setObjectName(QString::fromUtf8("inj2PwmUp"));
        inj2PwmUp->setMaximum(2000);
        inj2PwmUp->setValue(1000);

        SettingsBox->addWidget(inj2PwmUp, 6, 2, 1, 1);

        inj3PwmDown = new QSpinBox(gridLayoutWidget);
        inj3PwmDown->setObjectName(QString::fromUtf8("inj3PwmDown"));
        inj3PwmDown->setMaximum(2000);
        inj3PwmDown->setValue(1800);

        SettingsBox->addWidget(inj3PwmDown, 7, 3, 1, 1);

        inj2EjectVolume = new QDoubleSpinBox(gridLayoutWidget);
        inj2EjectVolume->setObjectName(QString::fromUtf8("inj2EjectVolume"));

        SettingsBox->addWidget(inj2EjectVolume, 5, 2, 1, 1);

        inj2_name = new QLineEdit(gridLayoutWidget);
        inj2_name->setObjectName(QString::fromUtf8("inj2_name"));

        SettingsBox->addWidget(inj2_name, 1, 2, 1, 1);

        label_3 = new QLabel(gridLayoutWidget);
        label_3->setObjectName(QString::fromUtf8("label_3"));

        SettingsBox->addWidget(label_3, 3, 0, 1, 1);

        inj3_Speed = new QComboBox(gridLayoutWidget);
        inj3_Speed->addItem(QString());
        inj3_Speed->addItem(QString());
        inj3_Speed->addItem(QString());
        inj3_Speed->addItem(QString());
        inj3_Speed->addItem(QString());
        inj3_Speed->setObjectName(QString::fromUtf8("inj3_Speed"));

        SettingsBox->addWidget(inj3_Speed, 2, 3, 1, 1);

        label_2 = new QLabel(gridLayoutWidget);
        label_2->setObjectName(QString::fromUtf8("label_2"));

        SettingsBox->addWidget(label_2, 7, 0, 1, 1);

        inj1PwmDown = new QSpinBox(gridLayoutWidget);
        inj1PwmDown->setObjectName(QString::fromUtf8("inj1PwmDown"));
        inj1PwmDown->setMaximum(2000);
        inj1PwmDown->setValue(1800);

        SettingsBox->addWidget(inj1PwmDown, 7, 1, 1, 1);

        inj1PwmUp = new QSpinBox(gridLayoutWidget);
        inj1PwmUp->setObjectName(QString::fromUtf8("inj1PwmUp"));
        inj1PwmUp->setMaximum(2000);
        inj1PwmUp->setValue(1000);

        SettingsBox->addWidget(inj1PwmUp, 6, 1, 1, 1);

        inj1_Speed = new QComboBox(gridLayoutWidget);
        inj1_Speed->addItem(QString());
        inj1_Speed->addItem(QString());
        inj1_Speed->addItem(QString());
        inj1_Speed->addItem(QString());
        inj1_Speed->addItem(QString());
        inj1_Speed->setObjectName(QString::fromUtf8("inj1_Speed"));

        SettingsBox->addWidget(inj1_Speed, 2, 1, 1, 1);

        inj1EjectVolume = new QDoubleSpinBox(gridLayoutWidget);
        inj1EjectVolume->setObjectName(QString::fromUtf8("inj1EjectVolume"));

        SettingsBox->addWidget(inj1EjectVolume, 5, 1, 1, 1);

        inj3_BubbleVolume = new QDoubleSpinBox(gridLayoutWidget);
        inj3_BubbleVolume->setObjectName(QString::fromUtf8("inj3_BubbleVolume"));
        inj3_BubbleVolume->setSingleStep(0.100000000000000);
        inj3_BubbleVolume->setValue(0.500000000000000);

        SettingsBox->addWidget(inj3_BubbleVolume, 4, 3, 1, 1);

        ejectV_label = new QLabel(gridLayoutWidget);
        ejectV_label->setObjectName(QString::fromUtf8("ejectV_label"));

        SettingsBox->addWidget(ejectV_label, 5, 0, 1, 1);

        bubbleV_label = new QLabel(gridLayoutWidget);
        bubbleV_label->setObjectName(QString::fromUtf8("bubbleV_label"));

        SettingsBox->addWidget(bubbleV_label, 4, 0, 1, 1);

        inj1_name = new QLineEdit(gridLayoutWidget);
        inj1_name->setObjectName(QString::fromUtf8("inj1_name"));

        SettingsBox->addWidget(inj1_name, 1, 1, 1, 1);

        inj3EjectVolume = new QDoubleSpinBox(gridLayoutWidget);
        inj3EjectVolume->setObjectName(QString::fromUtf8("inj3EjectVolume"));

        SettingsBox->addWidget(inj3EjectVolume, 5, 3, 1, 1);

        inj1_StepsPerMicroLiter = new QDoubleSpinBox(gridLayoutWidget);
        inj1_StepsPerMicroLiter->setObjectName(QString::fromUtf8("inj1_StepsPerMicroLiter"));
        inj1_StepsPerMicroLiter->setDecimals(0);
        inj1_StepsPerMicroLiter->setMaximum(1000.000000000000000);
        inj1_StepsPerMicroLiter->setValue(47.000000000000000);

        SettingsBox->addWidget(inj1_StepsPerMicroLiter, 3, 1, 1, 1);

        inj2_StepsPerMicroLiter = new QDoubleSpinBox(gridLayoutWidget);
        inj2_StepsPerMicroLiter->setObjectName(QString::fromUtf8("inj2_StepsPerMicroLiter"));
        inj2_StepsPerMicroLiter->setDecimals(0);
        inj2_StepsPerMicroLiter->setMaximum(1000.000000000000000);
        inj2_StepsPerMicroLiter->setValue(47.000000000000000);

        SettingsBox->addWidget(inj2_StepsPerMicroLiter, 3, 2, 1, 1);

        inj3_StepsPerMicroLiter = new QDoubleSpinBox(gridLayoutWidget);
        inj3_StepsPerMicroLiter->setObjectName(QString::fromUtf8("inj3_StepsPerMicroLiter"));
        inj3_StepsPerMicroLiter->setDecimals(0);
        inj3_StepsPerMicroLiter->setMaximum(1000.000000000000000);
        inj3_StepsPerMicroLiter->setValue(47.000000000000000);

        SettingsBox->addWidget(inj3_StepsPerMicroLiter, 3, 3, 1, 1);


        retranslateUi(SettingsInjectorDialog);

        QMetaObject::connectSlotsByName(SettingsInjectorDialog);
    } // setupUi

    void retranslateUi(QDialog *SettingsInjectorDialog)
    {
        SettingsInjectorDialog->setWindowTitle(QApplication::translate("SettingsInjectorDialog", "Injector Settings", nullptr));
        applyButton->setText(QApplication::translate("SettingsInjectorDialog", "Apply", nullptr));
        name_label->setText(QApplication::translate("SettingsInjectorDialog", "Injector Name", nullptr));
        label->setText(QApplication::translate("SettingsInjectorDialog", "PWM Up (\302\265s)", nullptr));
        inj2_Speed->setItemText(0, QApplication::translate("SettingsInjectorDialog", "Fastest", nullptr));
        inj2_Speed->setItemText(1, QApplication::translate("SettingsInjectorDialog", "Fast", nullptr));
        inj2_Speed->setItemText(2, QApplication::translate("SettingsInjectorDialog", "Normal", nullptr));
        inj2_Speed->setItemText(3, QApplication::translate("SettingsInjectorDialog", "Slow", nullptr));
        inj2_Speed->setItemText(4, QApplication::translate("SettingsInjectorDialog", "Slowest", nullptr));

        inj2_label->setText(QApplication::translate("SettingsInjectorDialog", "Injector 2", nullptr));
        inj1_label->setText(QApplication::translate("SettingsInjectorDialog", "Injector 1", nullptr));
        inj3_label->setText(QApplication::translate("SettingsInjectorDialog", "Injector 3", nullptr));
        speed_label->setText(QApplication::translate("SettingsInjectorDialog", "Injector Speed", nullptr));
        inj3_name->setText(QApplication::translate("SettingsInjectorDialog", "IsoProterenol", nullptr));
        inj2_name->setText(QApplication::translate("SettingsInjectorDialog", "IBMX", nullptr));
        label_3->setText(QApplication::translate("SettingsInjectorDialog", "Steps per \302\265L", nullptr));
        inj3_Speed->setItemText(0, QApplication::translate("SettingsInjectorDialog", "Fastest", nullptr));
        inj3_Speed->setItemText(1, QApplication::translate("SettingsInjectorDialog", "Fast", nullptr));
        inj3_Speed->setItemText(2, QApplication::translate("SettingsInjectorDialog", "Normal", nullptr));
        inj3_Speed->setItemText(3, QApplication::translate("SettingsInjectorDialog", "Slow", nullptr));
        inj3_Speed->setItemText(4, QApplication::translate("SettingsInjectorDialog", "Slowest", nullptr));

        label_2->setText(QApplication::translate("SettingsInjectorDialog", "PWM Down (\302\265s)", nullptr));
        inj1_Speed->setItemText(0, QApplication::translate("SettingsInjectorDialog", "Fastest", nullptr));
        inj1_Speed->setItemText(1, QApplication::translate("SettingsInjectorDialog", "Fast", nullptr));
        inj1_Speed->setItemText(2, QApplication::translate("SettingsInjectorDialog", "Normal", nullptr));
        inj1_Speed->setItemText(3, QApplication::translate("SettingsInjectorDialog", "Slow", nullptr));
        inj1_Speed->setItemText(4, QApplication::translate("SettingsInjectorDialog", "Slowest", nullptr));

        ejectV_label->setText(QApplication::translate("SettingsInjectorDialog", "Eject Mix Volume (\302\265L)", nullptr));
        bubbleV_label->setText(QApplication::translate("SettingsInjectorDialog", "Bubble Volume (\302\265L)", nullptr));
        inj1_name->setText(QApplication::translate("SettingsInjectorDialog", "Forskolin", nullptr));
    } // retranslateUi

};

namespace Ui {
    class SettingsInjectorDialog: public Ui_SettingsInjectorDialog {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_SETTINGSINJECTORDIALOG_H
