#include "PlainFormatter.h"

// Plain/numeric: [N] Author. Title. Year.
QString PlainFormatter::formatFootnote(const BibEntry &entry,
                                       const QString &pinpoint,
                                       const QVector<CitationHistoryEntry> &history,
                                       int currentFootnoteNumber) const
{
    Q_UNUSED(history)

    if (entry.key.isEmpty())
        return QStringLiteral("[unknown reference]");

    QString result = QStringLiteral("[") + QString::number(currentFootnoteNumber) + QStringLiteral("] ");

    QString author = entry.field(QStringLiteral("author"));
    QString title = entry.field(QStringLiteral("title"));
    QString year = entry.field(QStringLiteral("year"));

    if (!author.isEmpty())
        result += author + QStringLiteral(". ");

    if (!title.isEmpty())
        result += italicize(title) + QStringLiteral(". ");

    // Journal info
    QString journal = entry.field(QStringLiteral("journal"));
    QString volume = entry.field(QStringLiteral("volume"));
    QString pages = entry.field(QStringLiteral("pages"));

    if (!journal.isEmpty()) {
        result += journal;
        if (!volume.isEmpty())
            result += QStringLiteral(", ") + volume;
        if (!pages.isEmpty())
            result += QStringLiteral(":") + pages;
        result += QStringLiteral(", ");
    }

    if (!year.isEmpty())
        result += year + QStringLiteral(".");

    if (!pinpoint.isEmpty())
        result += QStringLiteral(" ") + pinpoint;

    return result;
}
