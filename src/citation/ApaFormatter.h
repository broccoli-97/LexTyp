#ifndef APAFORMATTER_H
#define APAFORMATTER_H

#include "citation/CitationFormatter.h"
#include "bib/BibEntry.h"

class ApaFormatter : public CitationFormatter
{
public:
    QString formatFootnote(const BibEntry &entry,
                           const QString &pinpoint,
                           const QVector<CitationHistoryEntry> &history,
                           int currentFootnoteNumber) const override;

    QString styleName() const override { return QStringLiteral("apa"); }
};

#endif // APAFORMATTER_H
