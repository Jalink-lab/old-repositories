#ifndef INJECTORSETTINGSDIALOG_H
#define INJECTORSETTINGSDIALOG_H

#include <QDialog>

QT_BEGIN_NAMESPACE

namespace Ui {
class InjectorSettingsDialog;
}

class QIntValidator;

QT_END_NAMESPACE

class InjectorSettingsDialog : public QDialog
{
    Q_OBJECT

public:
    struct InjectorSettings1 {
        QString name;
        qint32 speed;
        qint32 bubbleVolume;
    };
    struct InjectorSettings2 {
        QString name;
        qint32 speed;
        qint32 bubbleVolume;
    };
    struct InjectorSettings3 {
        QString name;
        qint32 speed;
        qint32 bubbleVolume;
    };

    explicit InjectorSettingsDialog(QWidget *parent = nullptr);
    ~InjectorSettingsDialog();

    InjectorSettings1 settings() const;
};

#endif // INJECTORSETTINGSDIALOG_H
