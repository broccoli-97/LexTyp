#include "TexTemplateParser.h"

#include <QFile>
#include <QRegularExpression>
#include <QTextStream>

QString TexTemplateParser::extractBibliographyStyle(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};

    QTextStream in(&file);
    QString contents = in.readAll();

    // Match \bibliographystyle{stylename}
    static const QRegularExpression rx(
        QStringLiteral("\\\\bibliographystyle\\{([^}]+)\\}"));
    auto match = rx.match(contents);
    if (match.hasMatch())
        return match.captured(1).trimmed();

    return {};
}
