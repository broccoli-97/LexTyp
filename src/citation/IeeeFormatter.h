#ifndef IEEEFORMATTER_H
#define IEEEFORMATTER_H

#include "citation/CitationFormatter.h"
#include "bib/BibEntry.h"

class IeeeFormatter : public CitationFormatter
{
public:
    QString formatFootnote(const BibEntry &entry,
                           const QString &pinpoint,
                           const QVector<CitationHistoryEntry> &history,
                           int currentFootnoteNumber) const override;

    QString styleName() const override { return QStringLiteral("ieee"); }
};

#endif // IEEEFORMATTER_H
