#include "DocumentModel.h"

#include "ast/TitleNode.h"
#include "ast/ParagraphNode.h"
#include "ast/CitationNode.h"
#include "ast/SectionNode.h"
#include "bib/BibParser.h"
#include "TypstSerializer.h"
#include "citation/CitationFormatter.h"
#include "citation/CitationStyleRegistry.h"
#include "citation/TexTemplateParser.h"

DocumentModel::DocumentModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_registry(&CitationStyleRegistry::instance())
    , m_formatter(m_registry->defaultFormatter())
{
    m_compileTimer.setSingleShot(true);
    m_compileTimer.setInterval(400);
    connect(&m_compileTimer, &QTimer::timeout, this, [this]() {
        Q_ASSERT(m_formatter);
        QString source = TypstSerializer::serialize(m_nodes, m_library, *m_formatter);
        if (source == m_lastSource)
            return;
        m_lastSource = source;
        emit typstSourceChanged(source);
    });

    // Seed with default blocks
    m_nodes.append(std::make_shared<TitleNode>(QStringLiteral("Untitled"), 1));
    m_nodes.append(std::make_shared<ParagraphNode>());
}

int DocumentModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_nodes.size();
}

QVariant DocumentModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_nodes.size())
        return {};

    const auto &node = m_nodes.at(index.row());

    switch (role) {
    case NodeTypeRole:
        return static_cast<int>(node->type());
    case ContentRole:
        return node->content();
    case NodeIdRole:
        return node->id().toString(QUuid::WithoutBraces);
    case LevelRole:
        if (auto *title = node->as<TitleNode>())
            return title->level();
        return 0;
    case PrefixRole:
        if (auto *cite = node->as<CitationNode>())
            return cite->prefix();
        return QString();
    case SuffixRole:
        if (auto *cite = node->as<CitationNode>())
            return cite->suffix();
        return QString();
    }

    return {};
}

bool DocumentModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_nodes.size())
        return false;

    auto &node = m_nodes[index.row()];

    switch (role) {
    case ContentRole:
        node->setContent(value.toString());
        break;
    case LevelRole:
        if (auto *title = node->as<TitleNode>()) {
            title->setLevel(value.toInt());
        } else {
            return false;
        }
        break;
    case PrefixRole:
        if (auto *cite = node->as<CitationNode>()) {
            cite->setPrefix(value.toString());
        } else {
            return false;
        }
        break;
    case SuffixRole:
        if (auto *cite = node->as<CitationNode>()) {
            cite->setSuffix(value.toString());
        } else {
            return false;
        }
        break;
    default:
        return false;
    }

    emit dataChanged(index, index, {role});
    scheduleSerialization();
    return true;
}

QHash<int, QByteArray> DocumentModel::roleNames() const
{
    return {
        {NodeTypeRole, "nodeType"},
        {ContentRole, "content"},
        {NodeIdRole, "nodeId"},
        {LevelRole, "level"},
        {PrefixRole, "prefix"},
        {SuffixRole, "suffix"}
    };
}

Qt::ItemFlags DocumentModel::flags(const QModelIndex &index) const
{
    if (!index.isValid())
        return Qt::NoItemFlags;
    return Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsEditable;
}

void DocumentModel::insertNode(int row, int nodeType)
{
    row = qBound(0, row, m_nodes.size());
    auto node = createNode(static_cast<NodeType>(nodeType));
    if (!node)
        return;

    beginInsertRows(QModelIndex(), row, row);
    m_nodes.insert(row, node);
    endInsertRows();
    scheduleSerialization();
}

void DocumentModel::removeNode(int row)
{
    if (row < 0 || row >= m_nodes.size())
        return;

    beginRemoveRows(QModelIndex(), row, row);
    m_nodes.removeAt(row);
    endRemoveRows();
    scheduleSerialization();
}

void DocumentModel::moveNode(int from, int to)
{
    if (from < 0 || from >= m_nodes.size() || to < 0 || to >= m_nodes.size() || from == to)
        return;

    // QAbstractItemModel::beginMoveRows destination index convention:
    // when moving down, destination must be > source + 1
    int dest = to > from ? to + 1 : to;
    if (!beginMoveRows(QModelIndex(), from, from, QModelIndex(), dest))
        return;

    // Use Qt's move for the underlying vector
    if (from < to) {
        // Moving down: rotate left
        std::rotate(m_nodes.begin() + from, m_nodes.begin() + from + 1, m_nodes.begin() + to + 1);
    } else {
        // Moving up: rotate right
        std::rotate(m_nodes.begin() + to, m_nodes.begin() + from, m_nodes.begin() + from + 1);
    }

    endMoveRows();
    scheduleSerialization();
}

void DocumentModel::changeNodeType(int row, int newType)
{
    if (row < 0 || row >= m_nodes.size())
        return;

    auto oldNode = m_nodes.at(row);
    if (static_cast<int>(oldNode->type()) == newType)
        return;

    auto newNode = createNode(static_cast<NodeType>(newType));
    if (!newNode)
        return;

    // Preserve content where possible
    newNode->setContent(oldNode->content());

    m_nodes[row] = newNode;
    emit dataChanged(index(row), index(row));
    scheduleSerialization();
}

int DocumentModel::nodeCount() const
{
    return m_nodes.size();
}

void DocumentModel::insertNodeBelow(int row, int nodeType)
{
    insertNode(row + 1, nodeType);
}

void DocumentModel::setNodeContent(int row, const QString &value)
{
    setData(index(row), value, ContentRole);
}

void DocumentModel::setNodeLevel(int row, int value)
{
    setData(index(row), value, LevelRole);
}

void DocumentModel::setNodePrefix(int row, const QString &value)
{
    setData(index(row), value, PrefixRole);
}

void DocumentModel::setNodeSuffix(int row, const QString &value)
{
    setData(index(row), value, SuffixRole);
}

void DocumentModel::setReferenceLibrary(ReferenceLibrary *library)
{
    m_library = library;
    scheduleSerialization();
}

void DocumentModel::insertInlineCitation(int row, int cursorPos, const QString &key)
{
    if (row < 0 || row >= m_nodes.size())
        return;

    auto &node = m_nodes[row];
    if (node->type() != NodeType::Paragraph)
        return;

    QString text = node->content();
    cursorPos = qBound(0, cursorPos, text.length());

    // Build insertion string with surrounding spaces so the @key is
    // always delimited — prevents subsequent typing from extending it
    QString insert = QStringLiteral("@") + key;
    if (cursorPos > 0 && text[cursorPos - 1] != QLatin1Char(' '))
        insert.prepend(QLatin1Char(' '));
    // Always append trailing space (even at end of text)
    if (cursorPos >= text.length() || text[cursorPos] != QLatin1Char(' '))
        insert.append(QLatin1Char(' '));

    text.insert(cursorPos, insert);
    setNodeContent(row, text);
}

void DocumentModel::scheduleSerialization()
{
    m_compileTimer.start();
}

void DocumentModel::loadTexTemplate(const QUrl &fileUrl)
{
    QString filePath = fileUrl.toLocalFile();
    if (filePath.isEmpty())
        return;

    QString style = TexTemplateParser::extractBibliographyStyle(filePath);
    if (!style.isEmpty())
        setCitationStyle(style);
}

QString DocumentModel::citationStyle() const
{
    return m_citationStyle;
}

void DocumentModel::setCitationStyle(const QString &styleName)
{
    QString normalized = styleName.toLower().trimmed();
    if (normalized == m_citationStyle)
        return;

    m_citationStyle = normalized;
    m_formatter = m_registry->formatter(normalized);
    emit citationStyleChanged();
    scheduleSerialization();
}

std::shared_ptr<DocumentNode> DocumentModel::createNode(NodeType type) const
{
    switch (type) {
    case NodeType::Title:
        return std::make_shared<TitleNode>();
    case NodeType::Paragraph:
        return std::make_shared<ParagraphNode>();
    case NodeType::Citation:
        return std::make_shared<CitationNode>();
    case NodeType::Section:
        return std::make_shared<SectionNode>();
    }
    return nullptr;
}
