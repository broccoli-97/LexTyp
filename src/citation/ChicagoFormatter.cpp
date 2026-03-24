#include "ChicagoFormatter.h"

// Chicago notes-bibliography (footnote style) with ibid support
QString ChicagoFormatter::formatFootnote(const BibEntry &entry,
                                         const QString &pinpoint,
                                         const QVector<CitationHistoryEntry> &history,
                                         int currentFootnoteNumber) const
{
    Q_UNUSED(currentFootnoteNumber)

    if (entry.key.isEmpty())
        return QStringLiteral("[unknown reference]");

    // Ibid: same key as immediately preceding citation
    if (!history.isEmpty() && history.last().key == entry.key) {
        if (pinpoint.isEmpty())
            return QStringLiteral("Ibid.");
        return QStringLiteral("Ibid., ") + pinpoint;
    }

    // Short form: key appeared earlier
    for (const auto &prev : history) {
        if (prev.key == entry.key) {
            QString author = shortAuthor(entry.field(QStringLiteral("author")));
            QString title = entry.field(QStringLiteral("title"));
            // Shorten title to first few words
            QStringList words = title.split(QLatin1Char(' '));
            if (words.size() > 4)
                title = words.mid(0, 4).join(QLatin1Char(' ')) + QStringLiteral("...");

            QString result = author + QStringLiteral(", ") + italicize(title);
            if (!pinpoint.isEmpty())
                result += QStringLiteral(", ") + pinpoint;
            return result;
        }
    }

    // Full form
    QString author = entry.field(QStringLiteral("author"));
    QString title = entry.field(QStringLiteral("title"));
    QString year = entry.field(QStringLiteral("year"));

    QString result;

    if (!author.isEmpty())
        result += author + QStringLiteral(", ");

    // Books: italicized title; articles: quoted title
    if (!title.isEmpty()) {
        if (entry.type == QStringLiteral("article"))
            result += QStringLiteral("\"") + title + QStringLiteral(",\" ");
        else
            result += italicize(title);
    }

    // Article specifics
    QString journal = entry.field(QStringLiteral("journal"));
    QString volume = entry.field(QStringLiteral("volume"));
    QString number = entry.field(QStringLiteral("number"));
    QString pages = entry.field(QStringLiteral("pages"));

    if (!journal.isEmpty()) {
        result += QStringLiteral(" ") + italicize(journal);
        if (!volume.isEmpty()) {
            result += QStringLiteral(" ") + volume;
            if (!number.isEmpty())
                result += QStringLiteral(", no. ") + number;
        }
        if (!year.isEmpty())
            result += QStringLiteral(" (") + year + QStringLiteral(")");
        if (!pages.isEmpty())
            result += QStringLiteral(": ") + pages;
    } else {
        // Book: (Place: Publisher, Year)
        QString address = entry.field(QStringLiteral("address"));
        QString publisher = entry.field(QStringLiteral("publisher"));
        if (!address.isEmpty() || !publisher.isEmpty() || !year.isEmpty()) {
            result += QStringLiteral(" (");
            if (!address.isEmpty())
                result += address + QStringLiteral(": ");
            if (!publisher.isEmpty())
                result += publisher;
            if (!year.isEmpty()) {
                if (!publisher.isEmpty())
                    result += QStringLiteral(", ");
                result += year;
            }
            result += QStringLiteral(")");
        }
    }

    if (!pinpoint.isEmpty())
        result += QStringLiteral(", ") + pinpoint;

    return result;
}
