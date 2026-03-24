#include "HarvardFormatter.h"

// Harvard: Author (Year) Title. Place: Publisher.
QString HarvardFormatter::formatFootnote(const BibEntry &entry,
                                         const QString &pinpoint,
                                         const QVector<CitationHistoryEntry> &history,
                                         int currentFootnoteNumber) const
{
    Q_UNUSED(history)
    Q_UNUSED(currentFootnoteNumber)

    if (entry.key.isEmpty())
        return QStringLiteral("[unknown reference]");

    QString author = entry.field(QStringLiteral("author"));
    QString year = entry.field(QStringLiteral("year"));
    QString title = entry.field(QStringLiteral("title"));

    QString result;

    // Author (Year)
    if (!author.isEmpty())
        result += author;
    if (!year.isEmpty())
        result += QStringLiteral(" (") + year + QStringLiteral(")");
    if (!result.isEmpty())
        result += QStringLiteral(" ");

    // Title (italicized for books, in quotes for articles)
    if (!title.isEmpty()) {
        if (entry.type == QStringLiteral("article"))
            result += QStringLiteral("'") + title + QStringLiteral("', ");
        else
            result += italicize(title) + QStringLiteral(". ");
    }

    // Journal details (for articles)
    QString journal = entry.field(QStringLiteral("journal"));
    QString volume = entry.field(QStringLiteral("volume"));
    QString pages = entry.field(QStringLiteral("pages"));

    if (!journal.isEmpty()) {
        result += italicize(journal);
        if (!volume.isEmpty())
            result += QStringLiteral(", vol. ") + volume;
        if (!pages.isEmpty())
            result += QStringLiteral(", pp. ") + pages;
        result += QStringLiteral(".");
    }

    // Place: Publisher (for books)
    QString address = entry.field(QStringLiteral("address"));
    QString publisher = entry.field(QStringLiteral("publisher"));
    if (journal.isEmpty()) {
        if (!address.isEmpty())
            result += address + QStringLiteral(": ");
        if (!publisher.isEmpty())
            result += publisher + QStringLiteral(".");
    }

    if (!pinpoint.isEmpty())
        result += QStringLiteral(" ") + pinpoint;

    return result;
}
