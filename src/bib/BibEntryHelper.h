#ifndef BIBENTRYHELPER_H
#define BIBENTRYHELPER_H

#include <QObject>
#include <QQmlEngine>
#include <QVariantMap>

class BibEntryHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit BibEntryHelper(QObject *parent = nullptr);

    Q_INVOKABLE QString fieldLabel(const QString &key) const;
    Q_INVOKABLE bool isAcademicType(const QString &entryType) const;
    Q_INVOKABLE QVariantMap badgeInfo(const QString &entryType) const;
    Q_INVOKABLE QString secondaryInfo(const QString &entryType, const QVariantMap &fields) const;
    Q_INVOKABLE QString displayTitle(const QString &entryType, const QVariantMap &fields,
                                     const QString &key) const;

private:
    static const QHash<QString, QString> &fieldLabels();
};

#endif // BIBENTRYHELPER_H
