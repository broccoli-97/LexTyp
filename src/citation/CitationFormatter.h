#ifndef CITATIONFORMATTER_H
#define CITATIONFORMATTER_H

#include <QString>
#include <QVector>

class BibEntry;

struct CitationHistoryEntry {
    QString key;
    int footnoteNumber;
};

class CitationFormatter
{
public:
    virtual ~CitationFormatter() = default;

    virtual QString formatFootnote(const BibEntry &entry,
                                   const QString &pinpoint,
                                   const QVector<CitationHistoryEntry> &history,
                                   int currentFootnoteNumber) const = 0;

    virtual QString styleName() const = 0;

protected:
    // Shared helpers available to all formatters
    static QString shortAuthor(const QString &author);
    static QString italicize(const QString &text);
};

#endif // CITATIONFORMATTER_H
