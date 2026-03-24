#ifndef DOCUMENTMODEL_H
#define DOCUMENTMODEL_H

#include <QAbstractListModel>
#include <QQmlEngine>
#include <QTimer>
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

public:
    enum Roles {
        NodeTypeRole = Qt::UserRole + 1,
        ContentRole,
        NodeIdRole,
        LevelRole,
        PrefixRole,
        SuffixRole
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

    Q_INVOKABLE void setNodeContent(int row, const QString &value);
    Q_INVOKABLE void setNodeLevel(int row, int value);
    Q_INVOKABLE void setNodePrefix(int row, const QString &value);
    Q_INVOKABLE void setNodeSuffix(int row, const QString &value);

    Q_INVOKABLE void insertInlineCitation(int row, int cursorPos, const QString &key);
    Q_INVOKABLE void setReferenceLibrary(ReferenceLibrary *library);

    Q_INVOKABLE void loadTexTemplate(const QUrl &fileUrl);
    QString citationStyle() const;
    Q_INVOKABLE void setCitationStyle(const QString &styleName);

signals:
    void typstSourceChanged(const QString &source);
    void citationStyleChanged();

private:
    void scheduleSerialization();
    std::shared_ptr<DocumentNode> createNode(NodeType type) const;

    QVector<std::shared_ptr<DocumentNode>> m_nodes;
    QTimer m_compileTimer;
    QString m_lastSource;
    ReferenceLibrary *m_library = nullptr;
    CitationStyleRegistry *m_registry;
    QString m_citationStyle = QStringLiteral("oscola");
    std::shared_ptr<CitationFormatter> m_formatter;
};

#endif // DOCUMENTMODEL_H
