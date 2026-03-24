#ifndef OSCOLAFORMATTER_H
#define OSCOLAFORMATTER_H

#include <QString>
#include <QVector>
#include "bib/BibEntry.h"
#include "citation/CitationFormatter.h"

class OscolaFormatter : public CitationFormatter
{
public:
    // Virtual override — delegates to the static implementation
    QString formatFootnote(const BibEntry &entry,
                           const QString &pinpoint,
                           const QVector<CitationHistoryEntry> &history,
                           int currentFootnoteNumber) const override;

    QString styleName() const override { return QStringLiteral("oscola"); }

    // Static implementation (preserved for backwards compatibility)
    static QString formatFootnoteStatic(const BibEntry &entry,
                                        const QString &pinpoint,
                                        const QVector<CitationHistoryEntry> &history,
                                        int currentFootnoteNumber);

    // Case formatting
    static QString formatCaseFull(const BibEntry &entry, const QString &pinpoint);
    static QString formatCaseShort(const BibEntry &entry, const QString &pinpoint, int footnoteNum);

    // Legislation formatting
    static QString formatLegislationFull(const BibEntry &entry, const QString &pinpoint);

    // Book formatting
    static QString formatBookFull(const BibEntry &entry, const QString &pinpoint);
    static QString formatBookShort(const BibEntry &entry, const QString &pinpoint, int footnoteNum);

    // Academic citation formatting
    static QString formatArticleFull(const BibEntry &entry, const QString &pinpoint);
    static QString formatInProceedingsFull(const BibEntry &entry, const QString &pinpoint);
    static QString formatInCollectionFull(const BibEntry &entry, const QString &pinpoint);
    static QString formatThesisFull(const BibEntry &entry, const QString &pinpoint);
    static QString formatGenericShort(const BibEntry &entry, const QString &pinpoint, int footnoteNum);

    // Ibid
    static QString formatIbid(const QString &pinpoint);
};

#endif // OSCOLAFORMATTER_H
