#ifndef DOCUMENTNODE_H
#define DOCUMENTNODE_H

#include <QString>
#include <QUuid>
#include <QJsonObject>

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
    explicit DocumentNode(NodeType type, const QUuid &id)
        : m_id(id), m_type(type) {}
    virtual ~DocumentNode() = default;

    QUuid id() const { return m_id; }
    NodeType type() const { return m_type; }

    template<typename T> T *as() { return dynamic_cast<T*>(this); }
    template<typename T> const T *as() const { return dynamic_cast<const T*>(this); }

    virtual QString content() const = 0;
    virtual void setContent(const QString &text) = 0;

    virtual QJsonObject toJson() const {
        QJsonObject obj;
        obj[QStringLiteral("id")] = m_id.toString(QUuid::WithoutBraces);
        obj[QStringLiteral("type")] = static_cast<int>(m_type);
        obj[QStringLiteral("content")] = content();
        return obj;
    }

    static std::shared_ptr<DocumentNode> fromJson(const QJsonObject &obj);

private:
    QUuid m_id;
    NodeType m_type;
};

#endif // DOCUMENTNODE_H
