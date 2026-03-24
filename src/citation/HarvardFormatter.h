#ifndef HARVARDFORMATTER_H
#define HARVARDFORMATTER_H

#include "citation/CitationFormatter.h"
#include "bib/BibEntry.h"

class HarvardFormatter : public CitationFormatter
{
public:
    QString formatFootnote(const BibEntry &entry,
                           const QString &pinpoint,
                           const QVector<CitationHistoryEntry> &history,
                           int currentFootnoteNumber) const override;

    QString styleName() const override { return QStringLiteral("harvard"); }
};

#endif // HARVARDFORMATTER_H
