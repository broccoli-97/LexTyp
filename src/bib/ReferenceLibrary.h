#ifndef REFERENCELIBRARY_H
#define REFERENCELIBRARY_H

#include <QAbstractListModel>
#include <QQmlEngine>
#include <QVector>

#include "BibEntry.h"

class BibParser;

class ReferenceLibrary : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int entryCount READ entryCount NOTIFY libraryChanged)
    Q_PROPERTY(QString filePath READ filePath NOTIFY libraryChanged)

public:
    enum Roles {
        KeyRole = Qt::UserRole + 1,
        TypeRole,
        TitleRole,
        AuthorRole,
        YearRole,
        FieldsRole
    };

    explicit ReferenceLibrary(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void loadBibFile(const QString &path);
    Q_INVOKABLE QVariantList entries(const QString &typeFilter = QString()) const;
    Q_INVOKABLE QVariantMap entryByKey(const QString &key) const;
    Q_INVOKABLE QVariantList search(const QString &query) const;

    int entryCount() const { return m_entries.size(); }
    QString filePath() const { return m_filePath; }

    const QVector<BibEntry> &allEntries() const { return m_entries; }
    BibEntry findEntry(const QString &key) const;

signals:
    void libraryChanged();

private:
    QVariantMap entryToVariantMap(const BibEntry &entry) const;

    QVector<BibEntry> m_entries;
    QString m_filePath;
};

#endif // REFERENCELIBRARY_H
