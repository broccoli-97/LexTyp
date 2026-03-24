#include "ReferenceLibrary.h"
#include "BibParser.h"

ReferenceLibrary::ReferenceLibrary(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ReferenceLibrary::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_entries.size();
}

QVariant ReferenceLibrary::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_entries.size())
        return {};

    const auto &entry = m_entries.at(index.row());

    switch (role) {
    case KeyRole:
        return entry.key;
    case TypeRole:
        return entry.type;
    case TitleRole:
        return entry.field(QStringLiteral("title"));
    case AuthorRole:
        return entry.field(QStringLiteral("author"));
    case YearRole:
        return entry.field(QStringLiteral("year"));
    case FieldsRole: {
        QVariantMap map;
        for (auto it = entry.fields.constBegin(); it != entry.fields.constEnd(); ++it)
            map[it.key()] = it.value();
        return map;
    }
    }

    return {};
}

QHash<int, QByteArray> ReferenceLibrary::roleNames() const
{
    return {
        {KeyRole, "key"},
        {TypeRole, "entryType"},
        {TitleRole, "title"},
        {AuthorRole, "author"},
        {YearRole, "year"},
        {FieldsRole, "fields"}
    };
}

void ReferenceLibrary::loadBibFile(const QString &path)
{
    // Strip file:// prefix if present (from QML FileDialog)
    QString cleanPath = path;
    if (cleanPath.startsWith(QStringLiteral("file://")))
        cleanPath = cleanPath.mid(7);

    auto newEntries = BibParser::parse(cleanPath);

    beginResetModel();
    // Merge: replace existing keys, add new ones
    for (const auto &newEntry : newEntries) {
        bool found = false;
        for (int i = 0; i < m_entries.size(); ++i) {
            if (m_entries[i].key == newEntry.key) {
                m_entries[i] = newEntry;
                found = true;
                break;
            }
        }
        if (!found)
            m_entries.append(newEntry);
    }
    endResetModel();

    m_filePath = cleanPath;
    emit libraryChanged();
}

QVariantList ReferenceLibrary::entries(const QString &typeFilter) const
{
    QVariantList result;
    for (const auto &entry : m_entries) {
        if (!typeFilter.isEmpty() && entry.type != typeFilter)
            continue;
        result.append(entryToVariantMap(entry));
    }
    return result;
}

QVariantMap ReferenceLibrary::entryByKey(const QString &key) const
{
    for (const auto &entry : m_entries) {
        if (entry.key == key)
            return entryToVariantMap(entry);
    }
    return {};
}

QVariantList ReferenceLibrary::search(const QString &query) const
{
    if (query.isEmpty())
        return entries();

    QVariantList result;
    QString lowerQuery = query.toLower();
    for (const auto &entry : m_entries) {
        bool match = entry.key.toLower().contains(lowerQuery);
        if (!match) {
            for (auto it = entry.fields.constBegin(); it != entry.fields.constEnd(); ++it) {
                if (it.value().toLower().contains(lowerQuery)) {
                    match = true;
                    break;
                }
            }
        }
        if (match)
            result.append(entryToVariantMap(entry));
    }
    return result;
}

BibEntry ReferenceLibrary::findEntry(const QString &key) const
{
    for (const auto &entry : m_entries) {
        if (entry.key == key)
            return entry;
    }
    return {};
}

QVariantMap ReferenceLibrary::entryToVariantMap(const BibEntry &entry) const
{
    QVariantMap map;
    map[QStringLiteral("key")] = entry.key;
    map[QStringLiteral("type")] = entry.type;
    QVariantMap fieldsMap;
    for (auto it = entry.fields.constBegin(); it != entry.fields.constEnd(); ++it)
        fieldsMap[it.key()] = it.value();
    map[QStringLiteral("fields")] = fieldsMap;
    return map;
}
