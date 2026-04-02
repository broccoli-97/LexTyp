#ifndef SECTIONNODE_H
#define SECTIONNODE_H

#include "DocumentNode.h"

class SectionNode : public DocumentNode
{
public:
    explicit SectionNode(const QString &label = QString())
        : DocumentNode(NodeType::Section), m_label(label) {}
    SectionNode(const QString &label, const QUuid &id)
        : DocumentNode(NodeType::Section, id), m_label(label) {}

    QString content() const override { return m_label; }
    void setContent(const QString &text) override { m_label = text; }

private:
    QString m_label;
};

#endif // SECTIONNODE_H
