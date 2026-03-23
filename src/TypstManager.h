#ifndef TYPSTMANAGER_H
#define TYPSTMANAGER_H

#include <QObject>
#include <QProcess>
#include <QElapsedTimer>
#include <QQmlEngine>

class TypstManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool compiling READ compiling NOTIFY compilingChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(QString lastPdfPath READ lastPdfPath NOTIFY lastPdfPathChanged)
    Q_PROPERTY(qint64 lastDuration READ lastDuration NOTIFY lastDurationChanged)

public:
    explicit TypstManager(QObject *parent = nullptr);

    bool compiling() const;
    QString lastError() const;
    QString lastPdfPath() const;
    qint64 lastDuration() const;

    Q_INVOKABLE void compile(const QString &typContent);

signals:
    void compilingChanged();
    void lastErrorChanged();
    void lastPdfPathChanged();
    void lastDurationChanged();
    void compilationFinished(const QString &pdfPath);
    void compilationFailed(const QString &errorLog);

private:
    QString resolveTypstPath() const;

    bool m_compiling = false;
    QString m_lastError;
    QString m_lastPdfPath;
    qint64 m_lastDuration = 0;
    QElapsedTimer m_timer;
};

#endif // TYPSTMANAGER_H
