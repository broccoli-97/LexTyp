#ifndef CHICAGOFORMATTER_H
#define CHICAGOFORMATTER_H

#include "citation/CitationFormatter.h"
#include "bib/BibEntry.h"

class ChicagoFormatter : public CitationFormatter
{
public:
    QString formatFootnote(const BibEntry &entry,
                           const QString &pinpoint,
                           const QVector<CitationHistoryEntry> &history,
                           int currentFootnoteNumber) const override;

    QString styleName() const override { return QStringLiteral("chicago"); }
};

#endif // CHICAGOFORMATTER_H
