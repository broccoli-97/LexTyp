#ifndef TEXTEMPLATEPARSER_H
#define TEXTEMPLATEPARSER_H

#include <QString>

class TexTemplateParser
{
public:
    // Extract the first \bibliographystyle{...} value from a .tex file.
    // Returns empty string if not found.
    static QString extractBibliographyStyle(const QString &filePath);
};

#endif // TEXTEMPLATEPARSER_H
