#include "DocumentModel.h"

#include "TypstSerializer.h"
#include "ast/CitationNode.h"
#include "ast/ParagraphNode.h"
#include "ast/SectionNode.h"
#include "ast/TitleNode.h"
#include "citation/CitationStyleRegistry.h"

#include <QDir>
#include <QFile>
#include <QProcess>
#include <QTemporaryDir>
#include <QTextStream>
#include <QUrl>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFileInfo>
#include <QDateTime>

DocumentModel::DocumentModel(QObject* parent)
    : QAbstractListModel(parent),
      m_registry(&CitationStyleRegistry::instance()),
      m_formatter(m_registry->defaultFormatter()) {
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

int DocumentModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid())
        return 0;
    return m_nodes.size();
}

QVariant DocumentModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_nodes.size())
        return {};

    const auto& node = m_nodes.at(index.row());

    switch (role) {
        case NodeTypeRole:
            return static_cast<int>(node->type());
        case ContentRole:
            return node->content();
        case NodeIdRole:
            return node->id().toString(QUuid::WithoutBraces);
        case LevelRole:
            if (auto* title = node->as<TitleNode>())
                return title->level();
            return 0;
        case PrefixRole:
            if (auto* cite = node->as<CitationNode>())
                return cite->prefix();
            return QString();
        case SuffixRole:
            if (auto* cite = node->as<CitationNode>())
                return cite->suffix();
            return QString();
    }

    return {};
}

bool DocumentModel::setData(const QModelIndex& index, const QVariant& value, int role) {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_nodes.size())
        return false;

    auto& node = m_nodes[index.row()];

    switch (role) {
        case ContentRole:
            node->setContent(value.toString());
            break;
        case LevelRole:
            if (auto* title = node->as<TitleNode>()) {
                title->setLevel(value.toInt());
            } else {
                return false;
            }
            break;
        case PrefixRole:
            if (auto* cite = node->as<CitationNode>()) {
                cite->setPrefix(value.toString());
            } else {
                return false;
            }
            break;
        case SuffixRole:
            if (auto* cite = node->as<CitationNode>()) {
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

QHash<int, QByteArray> DocumentModel::roleNames() const {
    return {{NodeTypeRole, "nodeType"}, {ContentRole, "content"}, {NodeIdRole, "nodeId"},
            {LevelRole, "level"},       {PrefixRole, "prefix"},   {SuffixRole, "suffix"}};
}

Qt::ItemFlags DocumentModel::flags(const QModelIndex& index) const {
    if (!index.isValid())
        return Qt::NoItemFlags;
    return Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsEditable;
}

void DocumentModel::insertNode(int row, int nodeType) {
    row = qBound(0, row, m_nodes.size());
    auto node = createNode(static_cast<NodeType>(nodeType));
    if (!node)
        return;

    beginInsertRows(QModelIndex(), row, row);
    m_nodes.insert(row, node);
    endInsertRows();
    scheduleSerialization();
}

void DocumentModel::removeNode(int row) {
    if (row < 0 || row >= m_nodes.size())
        return;

    beginRemoveRows(QModelIndex(), row, row);
    m_nodes.removeAt(row);
    endRemoveRows();
    scheduleSerialization();
}

void DocumentModel::moveNode(int from, int to) {
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

void DocumentModel::changeNodeType(int row, int newType) {
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

int DocumentModel::nodeCount() const {
    return m_nodes.size();
}

void DocumentModel::insertNodeBelow(int row, int nodeType) {
    insertNode(row + 1, nodeType);
}

void DocumentModel::setNodeContent(int row, const QString& value) {
    setData(index(row), value, ContentRole);
}

void DocumentModel::setNodeLevel(int row, int value) {
    setData(index(row), value, LevelRole);
}

void DocumentModel::setNodePrefix(int row, const QString& value) {
    setData(index(row), value, PrefixRole);
}

void DocumentModel::setNodeSuffix(int row, const QString& value) {
    setData(index(row), value, SuffixRole);
}

void DocumentModel::setReferenceLibrary(ReferenceLibrary* library) {
    m_library = library;
    scheduleSerialization();
}

void DocumentModel::parseTypstSource(const QString& source) {
    beginResetModel();
    m_nodes.clear();

    QString currentParagraph;
    const QStringList lines = source.split(QLatin1Char('\n'));

    for (const QString& line : lines) {
        const QString trimmed = line.trimmed();

        if (trimmed.startsWith(QLatin1Char('='))) {
            if (!currentParagraph.trimmed().isEmpty()) {
                auto p = std::make_shared<ParagraphNode>();
                p->setContent(currentParagraph.trimmed());
                m_nodes.append(p);
                currentParagraph.clear();
            }
            int level = 0;
            while (level < trimmed.length() && trimmed[level] == QLatin1Char('='))
                level++;
            m_nodes.append(std::make_shared<TitleNode>(trimmed.mid(level).trimmed(), level));
        } else if (trimmed.isEmpty()) {
            if (!currentParagraph.trimmed().isEmpty()) {
                auto p = std::make_shared<ParagraphNode>();
                p->setContent(currentParagraph.trimmed());
                m_nodes.append(p);
                currentParagraph.clear();
            }
        } else if (trimmed.startsWith(QLatin1String("//")) ||
                   trimmed.startsWith(QLatin1String("#set ")) ||
                   trimmed.startsWith(QLatin1String("#let ")) ||
                   trimmed.startsWith(QLatin1String("#show ")) ||
                   trimmed.startsWith(QLatin1String("#import ")) ||
                   trimmed == QLatin1String("---")) {
            // Skip preamble directives and comments
        } else {
            if (!currentParagraph.isEmpty())
                currentParagraph += QLatin1Char(' ');
            currentParagraph += trimmed;
        }
    }

    if (!currentParagraph.trimmed().isEmpty()) {
        auto p = std::make_shared<ParagraphNode>();
        p->setContent(currentParagraph.trimmed());
        m_nodes.append(p);
    }

    if (m_nodes.isEmpty()) {
        m_nodes.append(std::make_shared<TitleNode>(QStringLiteral("Untitled"), 1));
        m_nodes.append(std::make_shared<ParagraphNode>());
    }

    endResetModel();
    scheduleSerialization();
}

void DocumentModel::newProject() {
    beginResetModel();
    m_nodes.clear();
    m_nodes.append(std::make_shared<TitleNode>(QStringLiteral("Untitled"), 1));
    m_nodes.append(std::make_shared<ParagraphNode>());
    endResetModel();

    m_currentProjectPath.clear();
    m_citationStyle = QStringLiteral("oscola");
    m_formatter = m_registry->defaultFormatter();
    emit citationStyleChanged();
    scheduleSerialization();
}

void DocumentModel::loadTypst(const QUrl& fileUrl) {
    const QString path = fileUrl.toLocalFile();
    if (path.isEmpty())
        return;
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return;
    parseTypstSource(QTextStream(&file).readAll());
}

void DocumentModel::loadTypstFromString(const QString& source) {
    parseTypstSource(source);
}

void DocumentModel::loadProject(const QUrl& fileUrl) {
    const QString zipPath = fileUrl.toLocalFile();
    if (zipPath.isEmpty())
        return;

    QTemporaryDir tempDir;
    if (!tempDir.isValid())
        return;

    QProcess proc;
    proc.start(QStringLiteral("unzip"),
               {QStringLiteral("-o"), zipPath, QStringLiteral("-d"), tempDir.path()});
    if (!proc.waitForFinished(10000) || proc.exitCode() != 0)
        return;

    QDir dir(tempDir.path());

    // Load document.json (AST source of truth) — preferred over .typ re-parsing
    bool loadedFromJson = false;
    if (dir.exists(QStringLiteral("document.json"))) {
        QFile f(dir.filePath(QStringLiteral("document.json")));
        if (f.open(QIODevice::ReadOnly)) {
            QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
            if (doc.isObject()) {
                QJsonObject root = doc.object();

                // Restore citation style
                if (root.contains(QStringLiteral("citation_style")))
                    setCitationStyle(root[QStringLiteral("citation_style")].toString());

                // Restore AST nodes
                QJsonArray nodesArr = root[QStringLiteral("nodes")].toArray();
                if (!nodesArr.isEmpty()) {
                    beginResetModel();
                    m_nodes.clear();
                    for (const QJsonValue &val : nodesArr) {
                        auto node = DocumentNode::fromJson(val.toObject());
                        if (node)
                            m_nodes.append(node);
                    }
                    if (m_nodes.isEmpty()) {
                        m_nodes.append(std::make_shared<TitleNode>(QStringLiteral("Untitled"), 1));
                        m_nodes.append(std::make_shared<ParagraphNode>());
                    }
                    endResetModel();
                    loadedFromJson = true;
                }
            }
        }
    }

    // Fallback: legacy format — load from .typ + lextyp.json metadata
    if (!loadedFromJson) {
        const QStringList typFiles = dir.entryList({QStringLiteral("*.typ")}, QDir::Files);
        if (!typFiles.isEmpty()) {
            QFile f(dir.filePath(typFiles.first()));
            if (f.open(QIODevice::ReadOnly | QIODevice::Text))
                parseTypstSource(QTextStream(&f).readAll());
        }

        if (dir.exists(QStringLiteral("lextyp.json"))) {
            QFile f(dir.filePath(QStringLiteral("lextyp.json")));
            if (f.open(QIODevice::ReadOnly)) {
                QJsonObject obj = QJsonDocument::fromJson(f.readAll()).object();
                if (obj.contains(QStringLiteral("citation_style")))
                    setCitationStyle(obj[QStringLiteral("citation_style")].toString());
            }
        }
    }

    // Load bibliography
    const QStringList bibFiles = dir.entryList({QStringLiteral("*.bib")}, QDir::Files);
    if (!bibFiles.isEmpty() && m_library)
        m_library->loadBibFile(dir.filePath(bibFiles.first()));

    m_currentProjectPath = zipPath;
    scheduleSerialization();
}

void DocumentModel::loadBibliography(const QUrl& fileUrl) {
    QString path = fileUrl.toLocalFile();
    if (path.isEmpty())
        return;

    if (m_library) {
        m_library->loadBibFile(path);
    }
}

bool DocumentModel::saveProject(const QUrl& fileUrl) {
    QString targetPath = fileUrl.toLocalFile();
    if (targetPath.isEmpty()) {
        targetPath = m_currentProjectPath;
    }

    if (targetPath.isEmpty()) {
        emit requestSaveAs();
        return false;
    }

    QTemporaryDir tempDir;
    if (!tempDir.isValid())
        return false;

    // 1. manifest.json — format envelope
    {
        QJsonObject manifest;
        manifest[QStringLiteral("format_version")] = 1;
        manifest[QStringLiteral("app_version")] = QStringLiteral("0.1.0");
        manifest[QStringLiteral("created")] = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);
        manifest[QStringLiteral("modified")] = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);

        QFile f(tempDir.filePath(QStringLiteral("manifest.json")));
        if (f.open(QIODevice::WriteOnly))
            f.write(QJsonDocument(manifest).toJson());
    }

    // 2. document.json — AST source of truth
    {
        QJsonObject docObj;
        docObj[QStringLiteral("citation_style")] = m_citationStyle;

        QJsonArray nodesArr;
        for (const auto &node : m_nodes)
            nodesArr.append(node->toJson());
        docObj[QStringLiteral("nodes")] = nodesArr;

        QFile f(tempDir.filePath(QStringLiteral("document.json")));
        if (f.open(QIODevice::WriteOnly))
            f.write(QJsonDocument(docObj).toJson());
    }

    // 3. references.bib — self-contained bibliography copy
    if (m_library && !m_library->filePath().isEmpty()) {
        QFile sourceBib(m_library->filePath());
        if (sourceBib.exists())
            QFile::copy(m_library->filePath(),
                        tempDir.filePath(QStringLiteral("references.bib")));
    }

    // 4. document.typ — serialized Typst output for portability
    {
        QFile f(tempDir.filePath(QStringLiteral("document.typ")));
        if (f.open(QIODevice::WriteOnly | QIODevice::Text)) {
            QTextStream out(&f);
            Q_ASSERT(m_formatter);
            out << TypstSerializer::serialize(m_nodes, m_library, *m_formatter);
        }
    }

    // 5. Zip everything into the target .lextyp file
    QProcess proc;
    proc.setWorkingDirectory(tempDir.path());
    proc.start(QStringLiteral("zip"),
               {QStringLiteral("-r"), QStringLiteral("-j"), targetPath, QStringLiteral(".")});
    if (!proc.waitForFinished(10000) || proc.exitCode() != 0)
        return false;

    m_currentProjectPath = targetPath;
    return true;
}

bool DocumentModel::exportTypst(const QUrl& fileUrl) {
    const QString path = fileUrl.toLocalFile();
    if (path.isEmpty())
        return false;

    QFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text))
        return false;

    QTextStream out(&f);
    Q_ASSERT(m_formatter);
    out << TypstSerializer::serialize(m_nodes, m_library, *m_formatter);
    return true;
}

void DocumentModel::insertInlineCitation(int row, int cursorPos, const QString& key) {
    if (row < 0 || row >= m_nodes.size())
        return;

    auto& node = m_nodes[row];
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

void DocumentModel::scheduleSerialization() {
    m_compileTimer.start();
}

QString DocumentModel::citationStyle() const {
    return m_citationStyle;
}

void DocumentModel::setCitationStyle(const QString& styleName) {
    QString normalized = styleName.toLower().trimmed();
    if (normalized == m_citationStyle)
        return;

    m_citationStyle = normalized;
    m_formatter = m_registry->formatter(normalized);
    emit citationStyleChanged();
    scheduleSerialization();
}

QStringList DocumentModel::availableStyles() const {
    return m_registry->styleNames();
}

std::shared_ptr<DocumentNode> DocumentModel::createNode(NodeType type) const {
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
