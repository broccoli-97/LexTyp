#ifndef PLAINFORMATTER_H
#define PLAINFORMATTER_H

#include "citation/CitationFormatter.h"
#include "bib/BibEntry.h"

class PlainFormatter : public CitationFormatter
{
public:
    QString formatFootnote(const BibEntry &entry,
                           const QString &pinpoint,
                           const QVector<CitationHistoryEntry> &history,
                           int currentFootnoteNumber) const override;

    QString styleName() const override { return QStringLiteral("plain"); }
};

#endif // PLAINFORMATTER_H
