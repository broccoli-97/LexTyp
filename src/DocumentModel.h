#ifndef DOCUMENTMODEL_H
#define DOCUMENTMODEL_H

#include <QAbstractListModel>
#include <QQmlEngine>
#include <QStandardPaths>
#include <QTimer>
#include <QUrl>
#include <QVector>
#include <memory>

#include "ast/DocumentNode.h"
#include "bib/ReferenceLibrary.h"

class CitationFormatter;
class CitationStyleRegistry;

class DocumentModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString citationStyle READ citationStyle WRITE setCitationStyle NOTIFY citationStyleChanged)
    Q_PROPERTY(QString documentsPath READ documentsPath CONSTANT)
    Q_PROPERTY(QUrl defaultProjectSaveUrl READ defaultProjectSaveUrl CONSTANT)
    Q_PROPERTY(QUrl defaultProjectFolderUrl READ defaultProjectFolderUrl CONSTANT)
    Q_PROPERTY(int activeParagraphIndex READ activeParagraphIndex WRITE setActiveParagraphIndex NOTIFY activeParagraphIndexChanged)
    Q_PROPERTY(int activeCursorPosition READ activeCursorPosition WRITE setActiveCursorPosition NOTIFY activeCursorPositionChanged)

public:
    enum Roles {
        NodeTypeRole = Qt::UserRole + 1,
        ContentRole,
        NodeIdRole,
        LevelRole,
        PrefixRole,
        SuffixRole,
        TypeColorRole,
        TypeBgRole,
        TypeHoverBgRole
    };

    explicit DocumentModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;
    QHash<int, QByteArray> roleNames() const override;
    Qt::ItemFlags flags(const QModelIndex &index) const override;

    Q_INVOKABLE void insertNode(int row, int nodeType);
    Q_INVOKABLE void removeNode(int row);
    Q_INVOKABLE void moveNode(int from, int to);
    Q_INVOKABLE void changeNodeType(int row, int newType);
    Q_INVOKABLE int nodeCount() const;
    Q_INVOKABLE void insertNodeBelow(int row, int nodeType);
    Q_INVOKABLE void splitNode(int row, int cursorPos);

    Q_INVOKABLE void setNodeContent(int row, const QString &value);
    Q_INVOKABLE void setNodeLevel(int row, int value);
    Q_INVOKABLE void setNodePrefix(int row, const QString &value);
    Q_INVOKABLE void setNodeSuffix(int row, const QString &value);

    Q_INVOKABLE void insertInlineCitation(int row, int cursorPos, const QString &key);
    Q_INVOKABLE void insertCitation(const QString &key);
    Q_INVOKABLE void setReferenceLibrary(ReferenceLibrary *library);
    Q_INVOKABLE void setSerializationEnabled(bool enabled);

    Q_INVOKABLE void newProject();
    Q_INVOKABLE void loadTypst(const QUrl &fileUrl);
    Q_INVOKABLE void loadTypstFromString(const QString &source);
    Q_INVOKABLE void loadProject(const QUrl &fileUrl);
    Q_INVOKABLE void loadBibliography(const QUrl &fileUrl);
    Q_INVOKABLE bool saveProject(const QUrl &fileUrl = QUrl());
    Q_INVOKABLE bool exportTypst(const QUrl &fileUrl);

    QString citationStyle() const;
    QString documentsPath() const { return QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation); }
    QUrl defaultProjectSaveUrl() const {
        return QUrl::fromLocalFile(documentsPath() + QStringLiteral("/document.lextyp"));
    }
    QUrl defaultProjectFolderUrl() const {
        return QUrl::fromLocalFile(documentsPath());
    }
    Q_INVOKABLE void setCitationStyle(const QString &styleName);
    Q_INVOKABLE QStringList availableStyles() const;

    int activeParagraphIndex() const { return m_activeParagraphIndex; }
    void setActiveParagraphIndex(int idx);
    int activeCursorPosition() const { return m_activeCursorPosition; }
    void setActiveCursorPosition(int pos);

signals:
    void typstSourceChanged(const QString &source);
    void citationStyleChanged();
    void requestSaveAs();
    void activeParagraphIndexChanged();
    void activeCursorPositionChanged();
    void focusRequested(int row);

private:
    void scheduleSerialization();
    void parseTypstSource(const QString &source);
    std::shared_ptr<DocumentNode> createNode(NodeType type) const;

    static QString nodeTypeColor(NodeType type);
    static QString nodeTypeBg(NodeType type);
    static QString nodeTypeHoverBg(NodeType type);

    QVector<std::shared_ptr<DocumentNode>> m_nodes;
    QTimer m_compileTimer;
    QString m_lastSource;
    QString m_currentProjectPath;
    ReferenceLibrary *m_library = nullptr;
    CitationStyleRegistry *m_registry;
    QString m_citationStyle = QStringLiteral("oscola");
    std::shared_ptr<CitationFormatter> m_formatter;
    int m_activeParagraphIndex = -1;
    int m_activeCursorPosition = -1;
    bool m_serializationEnabled = true;
};

#endif // DOCUMENTMODEL_H
