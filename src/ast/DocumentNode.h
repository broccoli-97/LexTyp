#ifndef DOCUMENTNODE_H
#define DOCUMENTNODE_H

#include <QString>
#include <QUuid>

enum class NodeType {
    Title,
    Paragraph,
    Citation,
    Section
};

class DocumentNode
{
public:
    explicit DocumentNode(NodeType type)
        : m_id(QUuid::createUuid()), m_type(type) {}
    virtual ~DocumentNode() = default;

    QUuid id() const { return m_id; }
    NodeType type() const { return m_type; }

    virtual QString content() const = 0;
    virtual void setContent(const QString &text) = 0;

private:
    QUuid m_id;
    NodeType m_type;
};

#endif // DOCUMENTNODE_H
