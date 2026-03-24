#ifndef BIBPARSER_H
#define BIBPARSER_H

#include <QString>
#include <QVector>

#include "BibEntry.h"

class BibParser
{
public:
    static QVector<BibEntry> parse(const QString &filePath);

private:
    static QString stripBraces(const QString &value);
};

#endif // BIBPARSER_H
