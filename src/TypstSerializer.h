#ifndef TYPSTSERIALIZER_H
#define TYPSTSERIALIZER_H

#include <QVector>
#include <QString>
#include <memory>

class DocumentNode;
class ReferenceLibrary;

class TypstSerializer
{
public:
    static QString serialize(const QVector<std::shared_ptr<DocumentNode>> &nodes,
                             ReferenceLibrary *library = nullptr);
};

#endif // TYPSTSERIALIZER_H
