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
            if (entry.type == QStringLiteral("legislation"))
                return formatLegislationFull(entry, pinpoint);
            // All other types use generic short form: Surname (n X) pinpoint
            return formatGenericShort(entry, pinpoint, prev.footnoteNumber);
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
    if (entry.type == QStringLiteral("article"))
        return formatArticleFull(entry, pinpoint);
    if (entry.type == QStringLiteral("inproceedings") ||
        entry.type == QStringLiteral("conference"))
        return formatInProceedingsFull(entry, pinpoint);
    if (entry.type == QStringLiteral("incollection") ||
        entry.type == QStringLiteral("inbook"))
        return formatInCollectionFull(entry, pinpoint);
    if (entry.type == QStringLiteral("phdthesis") ||
        entry.type == QStringLiteral("mastersthesis"))
        return formatThesisFull(entry, pinpoint);

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

// Article: Author, 'Title' (Year) Volume Journal Pages
QString OscolaFormatter::formatArticleFull(const BibEntry &entry, const QString &pinpoint)
{
    QString author = entry.field(QStringLiteral("author"));
    QString title = entry.field(QStringLiteral("title"));
    QString journal = entry.field(QStringLiteral("journal"));
    QString volume = entry.field(QStringLiteral("volume"));
    QString pages = entry.field(QStringLiteral("pages"));
    QString year = entry.field(QStringLiteral("year"));

    QString result;
    if (!author.isEmpty())
        result += author + QStringLiteral(", ");

    if (!title.isEmpty())
        result += QStringLiteral("'") + title + QStringLiteral("'");

    if (!year.isEmpty())
        result += QStringLiteral(" (") + year + QStringLiteral(")");

    if (!volume.isEmpty())
        result += QStringLiteral(" ") + volume;

    if (!journal.isEmpty())
        result += QStringLiteral(" ") + italicize(journal);

    if (!pages.isEmpty())
        result += QStringLiteral(" ") + pages;

    if (!pinpoint.isEmpty())
        result += QStringLiteral(", ") + pinpoint;

    return result;
}

// Conference/proceedings: Author, 'Title' in _BookTitle_ (Publisher Year) Pages
QString OscolaFormatter::formatInProceedingsFull(const BibEntry &entry, const QString &pinpoint)
{
    QString author = entry.field(QStringLiteral("author"));
    QString title = entry.field(QStringLiteral("title"));
    QString booktitle = entry.field(QStringLiteral("booktitle"));
    QString publisher = entry.field(QStringLiteral("publisher"));
    QString year = entry.field(QStringLiteral("year"));
    QString pages = entry.field(QStringLiteral("pages"));

    QString result;
    if (!author.isEmpty())
        result += author + QStringLiteral(", ");

    if (!title.isEmpty())
        result += QStringLiteral("'") + title + QStringLiteral("'");

    if (!booktitle.isEmpty())
        result += QStringLiteral(" in ") + italicize(booktitle);

    if (!publisher.isEmpty() || !year.isEmpty()) {
        result += QStringLiteral(" (");
        if (!publisher.isEmpty())
            result += publisher;
        if (!publisher.isEmpty() && !year.isEmpty())
            result += QStringLiteral(" ");
        if (!year.isEmpty())
            result += year;
        result += QStringLiteral(")");
    }

    if (!pages.isEmpty())
        result += QStringLiteral(" ") + pages;

    if (!pinpoint.isEmpty())
        result += QStringLiteral(", ") + pinpoint;

    return result;
}

// Book chapter/collection: Author, 'Title' in Editor (ed), _BookTitle_ (Publisher Year) Pages
QString OscolaFormatter::formatInCollectionFull(const BibEntry &entry, const QString &pinpoint)
{
    QString author = entry.field(QStringLiteral("author"));
    QString title = entry.field(QStringLiteral("title"));
    QString editor = entry.field(QStringLiteral("editor"));
    QString booktitle = entry.field(QStringLiteral("booktitle"));
    QString publisher = entry.field(QStringLiteral("publisher"));
    QString year = entry.field(QStringLiteral("year"));
    QString pages = entry.field(QStringLiteral("pages"));

    QString result;
    if (!author.isEmpty())
        result += author + QStringLiteral(", ");

    if (!title.isEmpty())
        result += QStringLiteral("'") + title + QStringLiteral("'");

    if (!editor.isEmpty())
        result += QStringLiteral(" in ") + editor + QStringLiteral(" (ed), ");
    else if (!booktitle.isEmpty())
        result += QStringLiteral(" in ");

    if (!booktitle.isEmpty())
        result += italicize(booktitle);

    if (!publisher.isEmpty() || !year.isEmpty()) {
        result += QStringLiteral(" (");
        if (!publisher.isEmpty())
            result += publisher;
        if (!publisher.isEmpty() && !year.isEmpty())
            result += QStringLiteral(" ");
        if (!year.isEmpty())
            result += year;
        result += QStringLiteral(")");
    }

    if (!pages.isEmpty())
        result += QStringLiteral(" ") + pages;

    if (!pinpoint.isEmpty())
        result += QStringLiteral(", ") + pinpoint;

    return result;
}

// Thesis: Author, 'Title' (type, School Year)
QString OscolaFormatter::formatThesisFull(const BibEntry &entry, const QString &pinpoint)
{
    QString author = entry.field(QStringLiteral("author"));
    QString title = entry.field(QStringLiteral("title"));
    QString school = entry.field(QStringLiteral("school"));
    QString year = entry.field(QStringLiteral("year"));

    QString thesisType;
    if (entry.type == QStringLiteral("phdthesis"))
        thesisType = QStringLiteral("PhD thesis");
    else
        thesisType = QStringLiteral("MA thesis");

    QString result;
    if (!author.isEmpty())
        result += author + QStringLiteral(", ");

    if (!title.isEmpty())
        result += QStringLiteral("'") + title + QStringLiteral("'");

    result += QStringLiteral(" (") + thesisType;
    if (!school.isEmpty())
        result += QStringLiteral(", ") + school;
    if (!year.isEmpty())
        result += QStringLiteral(" ") + year;
    result += QStringLiteral(")");

    if (!pinpoint.isEmpty())
        result += QStringLiteral(" ") + pinpoint;

    return result;
}

// Generic short form for academic types: Surname (n X) pinpoint
QString OscolaFormatter::formatGenericShort(const BibEntry &entry, const QString &pinpoint, int footnoteNum)
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
