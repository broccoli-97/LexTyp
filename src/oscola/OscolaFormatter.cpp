#include "OscolaFormatter.h"

QString OscolaFormatter::formatFootnote(const BibEntry &entry,
                                        const QString &pinpoint,
                                        const QVector<CitationHistoryEntry> &history,
                                        int currentFootnoteNumber)
{
    if (entry.key.isEmpty())
        return QStringLiteral("[unknown reference]");

    // Check ibid: same key as immediately preceding citation
    if (!history.isEmpty() && history.last().key == entry.key)
        return formatIbid(pinpoint);

    // Check short form: key appeared earlier in history
    for (const auto &prev : history) {
        if (prev.key == entry.key) {
            if (entry.type == QStringLiteral("case"))
                return formatCaseShort(entry, pinpoint, prev.footnoteNumber);
            if (entry.type == QStringLiteral("book"))
                return formatBookShort(entry, pinpoint, prev.footnoteNumber);
            // Legislation doesn't change between first and subsequent
            return formatLegislationFull(entry, pinpoint);
        }
    }

    // Full form (first citation)
    Q_UNUSED(currentFootnoteNumber)
    if (entry.type == QStringLiteral("case"))
        return formatCaseFull(entry, pinpoint);
    if (entry.type == QStringLiteral("legislation"))
        return formatLegislationFull(entry, pinpoint);
    if (entry.type == QStringLiteral("book"))
        return formatBookFull(entry, pinpoint);

    // Fallback for unknown types
    QString text = entry.field(QStringLiteral("author"));
    if (!text.isEmpty())
        text += QStringLiteral(", ");
    text += italicize(entry.field(QStringLiteral("title")));
    if (!pinpoint.isEmpty())
        text += QStringLiteral(" ") + pinpoint;
    return text;
}

// OSCOLA case: _Party1 v Party2_ [year] court citation, pinpoint
QString OscolaFormatter::formatCaseFull(const BibEntry &entry, const QString &pinpoint)
{
    // 'author' field holds case parties, 'title' is case name (fallback)
    QString parties = entry.field(QStringLiteral("author"));
    if (parties.isEmpty())
        parties = entry.field(QStringLiteral("title"));

    QString result = italicize(parties);

    QString year = entry.field(QStringLiteral("year"));
    if (!year.isEmpty())
        result += QStringLiteral(" [") + year + QStringLiteral("]");

    QString court = entry.field(QStringLiteral("court"));
    if (!court.isEmpty())
        result += QStringLiteral(" ") + court;

    QString number = entry.field(QStringLiteral("number"));
    if (!number.isEmpty())
        result += QStringLiteral(" ") + number;

    if (!pinpoint.isEmpty())
        result += QStringLiteral(", ") + pinpoint;

    return result;
}

// OSCOLA case short form: _Party1_ (n X), pinpoint
QString OscolaFormatter::formatCaseShort(const BibEntry &entry, const QString &pinpoint, int footnoteNum)
{
    QString parties = entry.field(QStringLiteral("author"));
    if (parties.isEmpty())
        parties = entry.field(QStringLiteral("title"));

    // Use short name: first party only (before " v ")
    QString shortName = parties;
    int vPos = parties.indexOf(QStringLiteral(" v "));
    if (vPos > 0)
        shortName = parties.left(vPos);

    QString result = italicize(shortName);
    result += QStringLiteral(" (n ") + QString::number(footnoteNum) + QStringLiteral(")");

    if (!pinpoint.isEmpty())
        result += QStringLiteral(", ") + pinpoint;

    return result;
}

// OSCOLA legislation: Title Year, s X
QString OscolaFormatter::formatLegislationFull(const BibEntry &entry, const QString &pinpoint)
{
    QString title = entry.field(QStringLiteral("title"));
    QString year = entry.field(QStringLiteral("year"));

    QString result = title;
    if (!year.isEmpty())
        result += QStringLiteral(" ") + year;

    if (!pinpoint.isEmpty())
        result += QStringLiteral(", ") + pinpoint;

    return result;
}

// OSCOLA book first: Author, _Title_ (Publisher Year) pinpoint
QString OscolaFormatter::formatBookFull(const BibEntry &entry, const QString &pinpoint)
{
    QString author = entry.field(QStringLiteral("author"));
    QString title = entry.field(QStringLiteral("title"));
    QString publisher = entry.field(QStringLiteral("publisher"));
    QString year = entry.field(QStringLiteral("year"));

    QString result;
    if (!author.isEmpty())
        result += author + QStringLiteral(", ");

    result += italicize(title);

    // (Publisher Year)
    if (!publisher.isEmpty() || !year.isEmpty()) {
        result += QStringLiteral(" (");
        if (!publisher.isEmpty()) {
            result += publisher;
            if (!year.isEmpty())
                result += QStringLiteral(" ");
        }
        if (!year.isEmpty())
            result += year;
        result += QStringLiteral(")");
    }

    if (!pinpoint.isEmpty())
        result += QStringLiteral(" ") + pinpoint;

    return result;
}

// OSCOLA book short: Author surname (n X) pinpoint
QString OscolaFormatter::formatBookShort(const BibEntry &entry, const QString &pinpoint, int footnoteNum)
{
    QString author = shortAuthor(entry.field(QStringLiteral("author")));

    QString result = author;
    result += QStringLiteral(" (n ") + QString::number(footnoteNum) + QStringLiteral(")");

    if (!pinpoint.isEmpty())
        result += QStringLiteral(" ") + pinpoint;

    return result;
}

QString OscolaFormatter::formatIbid(const QString &pinpoint)
{
    if (pinpoint.isEmpty())
        return QStringLiteral("ibid");
    return QStringLiteral("ibid, ") + pinpoint;
}

// Extract last name from "First Last" or "Last, First" format
QString OscolaFormatter::shortAuthor(const QString &author)
{
    if (author.contains(QStringLiteral(", "))) {
        // "Last, First" format
        return author.left(author.indexOf(QStringLiteral(", ")));
    }
    // "First Last" format - take last word
    int lastSpace = author.lastIndexOf(QLatin1Char(' '));
    if (lastSpace > 0)
        return author.mid(lastSpace + 1);
    return author;
}

// Typst italic markup
QString OscolaFormatter::italicize(const QString &text)
{
    if (text.isEmpty())
        return text;
    return QStringLiteral("_") + text + QStringLiteral("_");
}
