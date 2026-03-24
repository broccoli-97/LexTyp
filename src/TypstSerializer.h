#ifndef TYPSTSERIALIZER_H
#define TYPSTSERIALIZER_H

#include <QVector>
#include <QString>
#include <memory>

class DocumentNode;
class ReferenceLibrary;
class CitationFormatter;

class TypstSerializer
{
public:
    static QString serialize(const QVector<std::shared_ptr<DocumentNode>> &nodes,
                             const ReferenceLibrary *library,
                             const CitationFormatter &formatter);
};

#endif // TYPSTSERIALIZER_H
