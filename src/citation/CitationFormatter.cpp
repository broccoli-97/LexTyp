#include "CitationFormatter.h"

QString CitationFormatter::shortAuthor(const QString &author)
{
    if (author.contains(QStringLiteral(", "))) {
        return author.left(author.indexOf(QStringLiteral(", ")));
    }
    int lastSpace = author.lastIndexOf(QLatin1Char(' '));
    if (lastSpace > 0)
        return author.mid(lastSpace + 1);
    return author;
}

QString CitationFormatter::italicize(const QString &text)
{
    if (text.isEmpty())
        return text;
    return QStringLiteral("_") + text + QStringLiteral("_");
}
