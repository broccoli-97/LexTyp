#ifndef TITLENODE_H
#define TITLENODE_H

#include "DocumentNode.h"

class TitleNode : public DocumentNode
{
public:
    explicit TitleNode(const QString &text = QString(), int level = 1)
        : DocumentNode(NodeType::Title), m_text(text), m_level(level) {}
    TitleNode(const QString &text, int level, const QUuid &id)
        : DocumentNode(NodeType::Title, id), m_text(text), m_level(level) {}

    QString content() const override { return m_text; }
    void setContent(const QString &text) override { m_text = text; }

    int level() const { return m_level; }
    void setLevel(int level) { m_level = qBound(1, level, 6); }

    QJsonObject toJson() const override {
        QJsonObject obj = DocumentNode::toJson();
        obj[QStringLiteral("level")] = m_level;
        return obj;
    }

private:
    QString m_text;
    int m_level;
};

#endif // TITLENODE_H
