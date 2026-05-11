/****************************************************************************
**
** Copyright (C) 2012 Denis Shienkov <denis.shienkov@gmail.com>
** Copyright (C) 2012 Laszlo Papp <lpapp@kde.org>
** Contact: https://www.qt.io/licensing/
**
** This file is part of the QtSerialPort module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include "settingsinjectordialog.h"
#include "ui_settingsinjectordialog.h"

#include <QIntValidator>
#include <QLineEdit>
#include <QSerialPortInfo>
#include <QSettings>

SettingsInjectorDialog::SettingsInjectorDialog(QWidget *parent) :
    QDialog(parent),
    m_ui(new Ui::SettingsInjectorDialog),
    m_intValidator(new QIntValidator(0, 4000000, this))
{
    m_ui->setupUi(this);

    connect(m_ui->applyButton, &QPushButton::clicked,
            this, &SettingsInjectorDialog::apply);
    loadSettings();
    updateSettings();
}

SettingsInjectorDialog::~SettingsInjectorDialog()
{
    delete m_ui;
}

SettingsInjectorDialog::InjectorSettings SettingsInjectorDialog::settings() const
{
    return m_currentSettings;
}



void SettingsInjectorDialog::apply()
{
    updateSettings();
    emit settingsInjectorApplyClicked();
    hide();
}
void SettingsInjectorDialog::loadSettings(){
    QSettings settings("Netherlands Cancer Institute", "JalinkLabInjector");
    settings.beginGroup("MainWindow");
    m_ui->inj1_name->setText(settings.value("name1","Forskolin").toString());
    m_ui->inj2_name->setText(settings.value("name2","IBMX").toString());
    m_ui->inj3_name->setText(settings.value("name3","Isoproterenol").toString());
    settings.endGroup();
    settings.beginGroup("InjectorSettings");
    m_ui->inj1_Speed->setCurrentIndex(settings.value("speed1",0).toInt());
    m_ui->inj2_Speed->setCurrentIndex(settings.value("speed2",0).toInt());
    m_ui->inj3_Speed->setCurrentIndex(settings.value("speed3",0).toInt());
    m_ui->inj1_StepsPerMicroLiter->setValue(settings.value("stepspermicroliter1",47).toDouble());
    m_ui->inj2_StepsPerMicroLiter->setValue(settings.value("stepspermicroliter2",47).toDouble());
    m_ui->inj3_StepsPerMicroLiter->setValue(settings.value("stepspermicroliter3",47).toDouble());
    m_ui->inj2_BubbleVolume->setValue(settings.value("bubbel2",0.5).toDouble());
    m_ui->inj3_BubbleVolume->setValue(settings.value("bubbel3",0.5).toDouble());
    m_ui->inj1_BubbleVolume->setValue(settings.value("bubbel1",0.5).toDouble());
    m_ui->inj2_BubbleVolume->setValue(settings.value("bubbel2",0.5).toDouble());
    m_ui->inj3_BubbleVolume->setValue(settings.value("bubbel3",0.5).toDouble());
    m_ui->inj1EjectVolume->setValue(settings.value("eject1",0).toDouble());
    m_ui->inj2EjectVolume->setValue(settings.value("eject2",0).toDouble());
    m_ui->inj3EjectVolume->setValue(settings.value("eject3",0).toDouble());
    m_ui->inj1PwmUp->setValue(settings.value("pwmUp1",1000).toInt());
    m_ui->inj2PwmUp->setValue(settings.value("pwmUp2",1000).toInt());
    m_ui->inj3PwmUp->setValue(settings.value("pwmUp3",1000).toInt());
    m_ui->inj1PwmDown->setValue(settings.value("pwmDown1",1800).toInt());
    m_ui->inj2PwmDown->setValue(settings.value("pwmDown2",1800).toInt());
    m_ui->inj3PwmDown->setValue(settings.value("pwmDown3",1800).toInt());
    settings.endGroup();
}
void SettingsInjectorDialog::updateSettings(){
    m_currentSettings.name1 = m_ui->inj1_name->text();
    m_currentSettings.name2 = m_ui->inj2_name->text();
    m_currentSettings.name3 = m_ui->inj3_name->text();
    m_currentSettings.speed1 = m_ui->inj1_Speed->currentIndex();
    m_currentSettings.speed2 = m_ui->inj2_Speed->currentIndex();
    m_currentSettings.speed3 = m_ui->inj3_Speed->currentIndex();
    m_currentSettings.stepsPerMicrolitre1 = m_ui->inj1_StepsPerMicroLiter->value(); //steps per microliter
    m_currentSettings.stepsPerMicrolitre2 = m_ui->inj2_StepsPerMicroLiter->value(); //steps per microliter
    m_currentSettings.stepsPerMicrolitre3 = m_ui->inj3_StepsPerMicroLiter->value(); //steps per microliter
    m_currentSettings.bubbleVolume1 = m_ui->inj1_BubbleVolume->value(); //nanolitres
    m_currentSettings.bubbleVolume2 = m_ui->inj2_BubbleVolume->value();
    m_currentSettings.bubbleVolume3 = m_ui->inj3_BubbleVolume->value();
    m_currentSettings.ejectMixVolume1 = m_ui->inj1EjectVolume->value(); //nanolitres
    m_currentSettings.ejectMixVolume2 = m_ui->inj2EjectVolume->value();
    m_currentSettings.ejectMixVolume3 = m_ui->inj3EjectVolume->value();
    m_currentSettings.pwmUp1 = m_ui->inj1PwmUp->value(); //nanolitres
    m_currentSettings.pwmUp2 = m_ui->inj2PwmUp->value();
    m_currentSettings.pwmUp3 = m_ui->inj3PwmUp->value();
    m_currentSettings.pwmDown1 = m_ui->inj1PwmDown->value(); //nanolitres
    m_currentSettings.pwmDown2 = m_ui->inj2PwmDown->value();
    m_currentSettings.pwmDown3 = m_ui->inj3PwmDown->value();
    QSettings settings("Netherlands Cancer Institute", "JalinkLabInjector");
    settings.beginGroup("MainWindow");
    settings.setValue("name1",m_currentSettings.name1);
    settings.setValue("name2",m_currentSettings.name2);
    settings.setValue("name3",m_currentSettings.name3);
    settings.endGroup();
    settings.beginGroup("InjectorSettings");
    settings.setValue("stepspermicroliter1",m_currentSettings.stepsPerMicrolitre1);
    settings.setValue("stepspermicroliter2",m_currentSettings.stepsPerMicrolitre2);
    settings.setValue("stepspermicroliter3",m_currentSettings.stepsPerMicrolitre3);
    settings.setValue("speed1",m_currentSettings.speed1);
    settings.setValue("speed2",m_currentSettings.speed2);
    settings.setValue("speed3",m_currentSettings.speed3);
    settings.setValue("bubbel1",m_currentSettings.bubbleVolume1);
    settings.setValue("bubbel2",m_currentSettings.bubbleVolume2);
    settings.setValue("bubbel3",m_currentSettings.bubbleVolume3);    
    settings.setValue("eject1",m_currentSettings.ejectMixVolume1);
    settings.setValue("eject2",m_currentSettings.ejectMixVolume2);
    settings.setValue("eject3",m_currentSettings.ejectMixVolume3);
    settings.setValue("pwmUp1",m_currentSettings.pwmUp1);
    settings.setValue("pwmUp2",m_currentSettings.pwmUp2);
    settings.setValue("pwmUp3",m_currentSettings.pwmUp3);
    settings.setValue("pwmDown1",m_currentSettings.pwmDown1);
    settings.setValue("pwmDown2",m_currentSettings.pwmDown2);
    settings.setValue("pwmDown3",m_currentSettings.pwmDown3);
    settings.endGroup();
}
