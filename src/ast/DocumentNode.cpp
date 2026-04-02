#include "DocumentNode.h"
#include "TitleNode.h"
#include "ParagraphNode.h"
#include "CitationNode.h"
#include "SectionNode.h"

std::shared_ptr<DocumentNode> DocumentNode::fromJson(const QJsonObject &obj)
{
    int typeInt = obj[QStringLiteral("type")].toInt(-1);
    QUuid id = QUuid::fromString(obj[QStringLiteral("id")].toString());
    if (id.isNull())
        id = QUuid::createUuid();

    QString content = obj[QStringLiteral("content")].toString();

    switch (static_cast<NodeType>(typeInt)) {
    case NodeType::Title: {
        int level = obj[QStringLiteral("level")].toInt(1);
        return std::make_shared<TitleNode>(content, level, id);
    }
    case NodeType::Paragraph:
        return std::make_shared<ParagraphNode>(content, id);
    case NodeType::Citation: {
        QString key = obj[QStringLiteral("key")].toString(content);
        QString prefix = obj[QStringLiteral("prefix")].toString();
        QString suffix = obj[QStringLiteral("suffix")].toString();
        return std::make_shared<CitationNode>(key, prefix, suffix, id);
    }
    case NodeType::Section:
        return std::make_shared<SectionNode>(content, id);
    default:
        return nullptr;
    }
}
