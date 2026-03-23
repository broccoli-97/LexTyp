#ifndef PARAGRAPHNODE_H
#define PARAGRAPHNODE_H

#include "DocumentNode.h"

class ParagraphNode : public DocumentNode
{
public:
    explicit ParagraphNode(const QString &text = QString())
        : DocumentNode(NodeType::Paragraph), m_text(text) {}

    QString content() const override { return m_text; }
    void setContent(const QString &text) override { m_text = text; }

private:
    QString m_text;
};

#endif // PARAGRAPHNODE_H
