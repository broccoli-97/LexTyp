#include "IeeeFormatter.h"

// IEEE: [N] A. Author, "Title," Journal, vol. X, no. Y, pp. Z, Year.
QString IeeeFormatter::formatFootnote(const BibEntry &entry,
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
        result += author + QStringLiteral(", ");

    if (!title.isEmpty())
        result += QStringLiteral("\"") + title + QStringLiteral(",\" ");

    // Article specifics
    QString journal = entry.field(QStringLiteral("journal"));
    QString volume = entry.field(QStringLiteral("volume"));
    QString number = entry.field(QStringLiteral("number"));
    QString pages = entry.field(QStringLiteral("pages"));

    if (!journal.isEmpty()) {
        result += italicize(journal);
        if (!volume.isEmpty())
            result += QStringLiteral(", vol. ") + volume;
        if (!number.isEmpty())
            result += QStringLiteral(", no. ") + number;
        if (!pages.isEmpty())
            result += QStringLiteral(", pp. ") + pages;
        if (!year.isEmpty())
            result += QStringLiteral(", ") + year;
        result += QStringLiteral(".");
    } else {
        // Book / other
        QString publisher = entry.field(QStringLiteral("publisher"));
        QString address = entry.field(QStringLiteral("address"));
        if (!address.isEmpty())
            result += address + QStringLiteral(": ");
        if (!publisher.isEmpty())
            result += publisher + QStringLiteral(", ");
        if (!year.isEmpty())
            result += year + QStringLiteral(".");
    }

    if (!pinpoint.isEmpty())
        result += QStringLiteral(" ") + pinpoint;

    return result;
}
