#include "ApaFormatter.h"

// APA 7th: Author, A. A. (Year). Title. Journal, Volume(Issue), Pages.
QString ApaFormatter::formatFootnote(const BibEntry &entry,
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

    // Author (Year).
    if (!author.isEmpty())
        result += author;
    if (!year.isEmpty())
        result += QStringLiteral(" (") + year + QStringLiteral(")");
    if (!result.isEmpty())
        result += QStringLiteral(". ");

    // Title (italicized for books, plain for articles)
    if (!title.isEmpty()) {
        if (entry.type == QStringLiteral("article"))
            result += title + QStringLiteral(". ");
        else
            result += italicize(title) + QStringLiteral(". ");
    }

    // Journal, Volume(Issue), Pages (for articles)
    QString journal = entry.field(QStringLiteral("journal"));
    QString volume = entry.field(QStringLiteral("volume"));
    QString number = entry.field(QStringLiteral("number"));
    QString pages = entry.field(QStringLiteral("pages"));

    if (!journal.isEmpty()) {
        result += italicize(journal);
        if (!volume.isEmpty()) {
            result += QStringLiteral(", ") + italicize(volume);
            if (!number.isEmpty())
                result += QStringLiteral("(") + number + QStringLiteral(")");
        }
        if (!pages.isEmpty())
            result += QStringLiteral(", ") + pages;
        result += QStringLiteral(".");
    }

    // Publisher (for books)
    QString publisher = entry.field(QStringLiteral("publisher"));
    if (journal.isEmpty() && !publisher.isEmpty())
        result += publisher + QStringLiteral(".");

    if (!pinpoint.isEmpty())
        result += QStringLiteral(" ") + pinpoint;

    return result;
}
