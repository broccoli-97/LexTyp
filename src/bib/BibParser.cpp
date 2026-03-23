#include "BibParser.h"

#include <QFile>
#include <QRegularExpression>
#include <QTextStream>

// ---------- BibParser ----------

QVector<BibEntry> BibParser::parse(const QString &filePath)
{
    QVector<BibEntry> entries;

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return entries;

    QString content = QTextStream(&file).readAll();
    file.close();

    // Match @type{key, ... }
    // We do a simple brace-depth parser rather than a single regex
    int pos = 0;
    QRegularExpression entryStart(QStringLiteral("@(\\w+)\\s*\\{\\s*([^,\\s]+)\\s*,"));

    while (pos < content.size()) {
        auto match = entryStart.match(content, pos);
        if (!match.hasMatch())
            break;

        BibEntry entry;
        entry.type = match.captured(1).toLower();
        entry.key = match.captured(2);

        // Find the fields between { ... }
        int braceStart = match.capturedEnd();
        int depth = 1;
        int i = match.capturedStart() + match.captured(0).indexOf(QLatin1Char('{')) + 1;
        // Skip past the key and comma
        i = braceStart;

        // Find matching closing brace
        int entryEnd = i;
        for (; entryEnd < content.size() && depth > 0; ++entryEnd) {
            if (content[entryEnd] == QLatin1Char('{'))
                ++depth;
            else if (content[entryEnd] == QLatin1Char('}'))
                --depth;
        }

        QString fieldBlock = content.mid(i, entryEnd - i - 1).trimmed();

        // Parse fields: name = {value} or name = "value" or name = number
        QRegularExpression fieldRe(QStringLiteral("(\\w+)\\s*=\\s*(?:\\{([^}]*)\\}|\"([^\"]*)\"|([\\w\\d]+))"));
        auto fieldIt = fieldRe.globalMatch(fieldBlock);
        while (fieldIt.hasNext()) {
            auto fm = fieldIt.next();
            QString fieldName = fm.captured(1).toLower();
            QString fieldValue = fm.captured(2);
            if (fieldValue.isEmpty())
                fieldValue = fm.captured(3);
            if (fieldValue.isEmpty())
                fieldValue = fm.captured(4);
            entry.fields[fieldName] = stripBraces(fieldValue);
        }

        entries.append(entry);
        pos = entryEnd;
    }

    return entries;
}

QString BibParser::stripBraces(const QString &value)
{
    QString result = value;
    result.remove(QLatin1Char('{'));
    result.remove(QLatin1Char('}'));
    return result.trimmed();
}

// ---------- ReferenceLibrary ----------

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
