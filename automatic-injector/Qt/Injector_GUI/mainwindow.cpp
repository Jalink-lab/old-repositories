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

#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "console.h"
#include "settingsdialog.h"
#include "settingsinjectordialog.h"

#include <QLabel>
#include <QMessageBox>
#include <QTime>
#include <QSettings>

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    m_ui(new Ui::MainWindow),
    m_status(new QLabel),
    m_console(new Console),
    m_settings(new SettingsDialog),
    m_settingsinjector(new SettingsInjectorDialog),
    m_serial(new QSerialPort(this))
{
    m_ui->setupUi(this);
    m_console->setEnabled(false);

    m_ui->actionConnect->setEnabled(true);
    m_ui->actionDisconnect->setEnabled(false);
    m_ui->actionQuit->setEnabled(true);
    m_ui->actionConfigure->setEnabled(true);
    m_ui->actionConfigureInjector->setEnabled(true);
    m_ui->statusBar->addWidget(m_status);

    initActionsConnections();
    connect(m_settingsinjector, &SettingsInjectorDialog::settingsInjectorApplyClicked, this, &MainWindow::updateInjectorNames);
    connect(m_serial, &QSerialPort::errorOccurred, this, &MainWindow::handleError);
    connect(m_serial, &QSerialPort::readyRead, this, &MainWindow::readData);
    connect(m_console, &Console::getData, this, &MainWindow::writeData);
    readSettings();
    const SettingsDialog::Settings p = m_settings->settings();
    if (p.foundArduino){
        openSerialPort();
    }
}

void MainWindow::writeSettings()
{
    QSettings settings("Netherlands Cancer Institute", "JalinkLabInjector");
    settings.beginGroup("MainWindow");
    settings.setValue("volume1",m_ui->inj1Volume->value());
    settings.setValue("volume2",m_ui->inj2Volume->value());
    settings.setValue("volume3",m_ui->inj3Volume->value());
    settings.setValue("name1",m_ui->inj1Label->text());
    settings.setValue("name2",m_ui->inj2Label->text());
    settings.setValue("name3",m_ui->inj3Label->text());
    settings.setValue("pos", pos());
    settings.endGroup();
}

void MainWindow::readSettings()
{
    QSettings settings("Netherlands Cancer Institute", "JalinkLabInjector");
    settings.beginGroup("MainWindow");
    move(settings.value("pos", QPoint(200, 200)).toPoint());
    m_ui->inj1Volume->setValue(settings.value("volume1",1).toDouble());
    m_ui->inj2Volume->setValue(settings.value("volume2",1).toDouble());
    m_ui->inj3Volume->setValue(settings.value("volume3",1).toDouble());
    m_ui->inj1Label->setText(settings.value("name1","Forskolin").toString());
    m_ui->inj2Label->setText(settings.value("name2","IBMX").toString());
    m_ui->inj3Label->setText(settings.value("name3","Isoproterenol").toString());
    settings.endGroup();
}

MainWindow::~MainWindow()
{
    writeSettings();
    delete m_settings;
    delete m_settingsinjector;
    delete m_console;
    delete m_ui;
}

void MainWindow::openSerialPort()
{
    const SettingsDialog::Settings p = m_settings->settings();
    m_serial->setPortName(p.name);
    m_serial->setBaudRate(p.baudRate);
    m_serial->setDataBits(p.dataBits);
    m_serial->setParity(p.parity);
    m_serial->setStopBits(p.stopBits);
    m_serial->setFlowControl(p.flowControl);
    if (m_serial->open(QIODevice::ReadWrite)) {
        m_console->setEnabled(true);
        m_console->setLocalEchoEnabled(p.localEchoEnabled);
        m_ui->actionConnect->setEnabled(false);
        m_ui->inj1Button->setEnabled(true);
        m_ui->inj2Button->setEnabled(true);
        m_ui->inj3Button->setEnabled(true);
        m_ui->actionDisconnect->setEnabled(true);
        m_ui->actionConfigure->setEnabled(false);
        showStatusMessage(tr("Connected to %1 : %2, %3, %4, %5, %6")
                          .arg(p.name).arg(p.stringBaudRate).arg(p.stringDataBits)
                          .arg(p.stringParity).arg(p.stringStopBits).arg(p.stringFlowControl));
        //store product identifier
        if (!p.productIdentifier.isEmpty()) {
            QSettings settings("Netherlands Cancer Institute", "JalinkLabInjector");
            settings.beginGroup("SerialSettings");
            settings.setValue("Product Identifier",p.productIdentifier);
            settings.endGroup();
        }

    } else {
        QMessageBox::critical(this, tr("Error"), m_serial->errorString());

        showStatusMessage(tr("Open error"));
    }
}

void MainWindow::closeSerialPort()
{
    if (m_serial->isOpen())
        m_serial->close();
    m_console->setEnabled(false);
    m_ui->actionConnect->setEnabled(true);
    m_ui->inj1Button->setEnabled(false);
    m_ui->inj2Button->setEnabled(false);
    m_ui->inj3Button->setEnabled(false);
    m_ui->actionDisconnect->setEnabled(false);
    m_ui->actionConfigure->setEnabled(true);
    showStatusMessage(tr("Disconnected"));
}

void MainWindow::about()
{
    QMessageBox::about(this, tr("About JalinkLab Injector"),
                       tr("A simple user interface to operate the automated injector. "
                          "It uses the serial interface to communicate to arduino. "
                          "Made using Qt-creator."));
}

void MainWindow::writeData(const QByteArray &data)
{
    m_serial->write(data);
}

void MainWindow::readData()
{
    const QByteArray data = m_serial->readAll();
    m_console->putData(data);
    lastMessage.append(data);
}

void MainWindow::handleError(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::ResourceError) {
        QMessageBox::critical(this, tr("Critical Error"), m_serial->errorString());
        closeSerialPort();
    }
}

void MainWindow::initActionsConnections()
{
    connect(m_ui->actionConnect, &QAction::triggered, this, &MainWindow::openSerialPort);
    connect(m_ui->actionDisconnect, &QAction::triggered, this, &MainWindow::closeSerialPort);
    connect(m_ui->actionQuit, &QAction::triggered, this, &MainWindow::close);
    connect(m_ui->actionConfigure, &QAction::triggered, m_settings, &SettingsDialog::show);
    connect(m_ui->actionConfigureInjector, &QAction::triggered, m_settingsinjector, &SettingsInjectorDialog::show);
    connect(m_ui->actionConsole,&QAction::triggered, m_console, &Console::show);
    connect(m_ui->actionClear, &QAction::triggered, m_console, &Console::clear);
    connect(m_ui->actionAbout, &QAction::triggered, this, &MainWindow::about);
    connect(m_ui->actionAboutQt, &QAction::triggered, qApp, &QApplication::aboutQt);
}

void MainWindow::updateInjectorNames(){

    const SettingsInjectorDialog::InjectorSettings p = m_settingsinjector->settings();
    m_ui->inj1Label->setText(p.name1);
    m_ui->inj2Label->setText(p.name2);
    m_ui->inj3Label->setText(p.name3);
}

void MainWindow::showStatusMessage(const QString &message)
{
    m_status->setText(message);
}

void MainWindow::on_inj1Button_clicked(bool checked)
{
    //perform action
    performAction(checked,1);
    //change apperance
    changeInjectorApperence(checked, m_ui->inj1Button,m_ui->inj1ImageLabel,m_ui->inj1Volume);
}

void MainWindow::on_inj2Button_clicked(bool checked)
{
    //perform action
    performAction(checked,2);
    //change apperance
    changeInjectorApperence(checked, m_ui->inj2Button,m_ui->inj2ImageLabel,m_ui->inj2Volume);
}

void MainWindow::on_inj3Button_clicked(bool checked)
{
    //perform action
    performAction(checked,3);
    //change apperance
    changeInjectorApperence(checked, m_ui->inj3Button,m_ui->inj3ImageLabel,m_ui->inj3Volume);
}

void MainWindow::performAction(bool checked,int injectorNumber){
    //disable buttons
    disableButtons(true);
    //load settings
    const SettingsInjectorDialog::InjectorSettings p = m_settingsinjector->settings();
    qint32 bubbleSteps=0;
    qint32 speed=0;
    qint32 injSteps=0;
    qint32 ejectMixSteps=0;
    qint32 pwmUp = 0;
    qint32 pwmDown = 0;
    switch (injectorNumber) {
        case 1:
            bubbleSteps = volumeToSteps(p.bubbleVolume1,p.speed1,p.stepsPerMicrolitre1);
            speed = p.speed1;
            injSteps =volumeToSteps(m_ui->inj1Volume->value(),p.speed1,p.stepsPerMicrolitre1);
            ejectMixSteps = volumeToSteps(p.ejectMixVolume1,p.speed1,p.stepsPerMicrolitre1);
            pwmUp = p.pwmUp1;
            pwmDown = p.pwmDown1;
            break;
        case 2:
            bubbleSteps = volumeToSteps(p.bubbleVolume2,p.speed2,p.stepsPerMicrolitre2);
            speed = p.speed2;
            injSteps = volumeToSteps(m_ui->inj2Volume->value(),p.speed1,p.stepsPerMicrolitre2);
            ejectMixSteps = volumeToSteps(p.ejectMixVolume2,p.speed2,p.stepsPerMicrolitre2);
            pwmUp = p.pwmUp2;
            pwmDown = p.pwmDown2;
            break;
        case 3:
            bubbleSteps = volumeToSteps(p.bubbleVolume3,p.speed3,p.stepsPerMicrolitre3);
            speed = p.speed3;
            injSteps = volumeToSteps(m_ui->inj3Volume->value(),p.speed1,p.stepsPerMicrolitre3);
            ejectMixSteps = volumeToSteps(p.ejectMixVolume3,p.speed3,p.stepsPerMicrolitre3);
            pwmUp = p.pwmUp3;
            pwmDown = p.pwmDown3;
            break;
    }
    QByteArray dataIn = *new QByteArray();
    QString qstrInjectorNumber = QString("%1").arg(injectorNumber, 1, 10, QChar('0'));
    dataIn.append(qstrInjectorNumber);
    if (checked){ //take up bubble , move down, take up volume, move up
        //take up bubble
        moveVolume(dataIn, '0', bubbleSteps, speed);
        //move down
        injectorUp(dataIn,false, pwmUp, pwmDown);
        //take up volume
        moveVolume(dataIn, '0', injSteps, speed);
        //wait a little bit more to take up volume completely
        WaitMsTime(qint32(1000));
        //move up
        injectorUp(dataIn,true, pwmUp, pwmDown);
    } else { //move down, eject bubble and volume together, move up
        //move down
        injectorUp(dataIn,false, pwmUp, pwmDown);
        //take-up volume
        moveVolume(dataIn, '0', ejectMixSteps, speed);
        //eject volume
        moveVolume(dataIn, '1', ejectMixSteps, speed);
        moveVolume(dataIn, '1', injSteps+bubbleSteps, speed);
        //wait a little bit more to eject volume completely
        WaitMsTime(qint32(1000));
        //move up
        injectorUp(dataIn,true, pwmUp, pwmDown);
    }
    //enable buttons
    disableButtons(false);
}
char* MainWindow::qStringToChar(QString in){
    QByteArray ba = in.toLocal8Bit();
    char *c_str2 = ba.data();
    return c_str2;
}
void MainWindow::injectorUp(QByteArray dataIn, bool up,qint32 pwmUp, qint32 pwmDown){
    dataIn.chop(dataIn.length()-1);
    QString setPWM = QString("%1").arg(pwmDown, 4, 10, QChar('0'));
    if (up){
        setPWM = QString("%1").arg(pwmUp, 4, 10, QChar('0'));
    }
    dataIn.append(setPWM);
    dataIn.append("\n");
    sendInjectorMessage(dataIn);
    WaitMsTime(qint32(2000)); //wait for move
}

void MainWindow::moveVolume(QByteArray dataIn, char direction, qint32 steps, qint32 speed){
    while (steps>0){ //injector can take 9999 steps per command
        qint32 takesteps = steps;
        if (takesteps>9999){
            takesteps = 9999;
        }
        steps = steps-takesteps;
        dataIn.chop(dataIn.length()-1);
        dataIn.append(direction);
        QString qstrVolume = QString("%1").arg(takesteps, 4, 10, QChar('0')); //number to '0'-padded string of length 4, radix 10
        dataIn.append(qstrVolume);
        QString qstrSpeed = QString("%1").arg(speed, 1, 10, QChar('0'));
        dataIn.append(qstrSpeed);
        dataIn.append("\n");
        sendInjectorMessage(dataIn);
    }
}

void MainWindow::sendInjectorMessage(QByteArray dataIn){
    QByteArray dataOut = dataIn;
    dataOut.chop(1);
    dataOut.append("_1\r\n"); //the injector responds with the same message appended with _1 on success
    //display in the message in the console
    m_console->putData(dataIn);
    //clear lastmessage
    lastMessage.clear();
    //write the message to the serial port
    m_serial->write(dataIn);
    //wait for finish
    int ct = 0;
    while (dataOut!=lastMessage&&ct<100){
        QTime dieTime = QTime::currentTime().addMSecs( 100 );
        while( QTime::currentTime() < dieTime ) {
            QCoreApplication::processEvents( QEventLoop::AllEvents, 100 );
        }
        ct++;
    }
    if (dataOut!=lastMessage){
        //need some sort of error signal
    }
}

void MainWindow::changeInjectorApperence(bool checked, QPushButton *injectorButton, QLabel *injectorPixelLabel, QDoubleSpinBox *injectorVolume){
    if (checked){
        injectorButton->setText("Eject");
        injectorPixelLabel->setPixmap(QPixmap(":/images/injector_full.png"));
        injectorVolume->setDisabled(true);
    } else {
        injectorButton->setText("Take-Up");
        injectorPixelLabel->setPixmap(QPixmap(":/images/injector_empty.png"));
        injectorVolume->setDisabled(false);
    }
}
void MainWindow::disableButtons(bool disable){
    m_ui->inj1Button->setDisabled(disable);
    m_ui->inj2Button->setDisabled(disable);
    m_ui->inj3Button->setDisabled(disable);
}
void MainWindow::WaitMsTime(qint32 waitms){
    QTime dieTime = QTime::currentTime().addMSecs( waitms );
    while( QTime::currentTime() < dieTime ) {
        QCoreApplication::processEvents( QEventLoop::AllEvents, 100 );
    }
}
int MainWindow::volumeToSteps(double microlitreVolume,int speed, double stepsPerMicroLiter){
    /* Injector Speed
     * 0 = Full step      1x
     * 1 = Half step      2x
     * 2 = Quarter step   4x
     * 3 = Eighth step    8x
     * 4 = Sixteenth step 16x
     */
    int factor = 1;
    factor = factor << speed; //bitshifting of integer == raising to power of 2
    double factorD = static_cast<double>(factor);
    factorD = 0.5 + factorD *  microlitreVolume*stepsPerMicroLiter; //round(x) == floor(x+0.5)
    return static_cast<int>(factorD);
}

void MainWindow::on_actionConfigureInjector_triggered()
{

}
