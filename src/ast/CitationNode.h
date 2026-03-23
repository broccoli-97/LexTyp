#ifndef CITATIONNODE_H
#define CITATIONNODE_H

#include "DocumentNode.h"

class CitationNode : public DocumentNode
{
public:
    explicit CitationNode(const QString &key = QString(),
                          const QString &prefix = QString(),
                          const QString &suffix = QString())
        : DocumentNode(NodeType::Citation), m_key(key), m_prefix(prefix), m_suffix(suffix) {}

    QString content() const override { return m_key; }
    void setContent(const QString &text) override { m_key = text; }

    QString key() const { return m_key; }
    void setKey(const QString &key) { m_key = key; }

    QString prefix() const { return m_prefix; }
    void setPrefix(const QString &prefix) { m_prefix = prefix; }

    QString suffix() const { return m_suffix; }
    void setSuffix(const QString &suffix) { m_suffix = suffix; }

private:
    QString m_key;
    QString m_prefix;
    QString m_suffix;
};

#endif // CITATIONNODE_H
