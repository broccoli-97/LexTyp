#ifndef REFERENCEFILTERMODEL_H
#define REFERENCEFILTERMODEL_H

#include <QQmlEngine>
#include <QSortFilterProxyModel>

class ReferenceFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString searchQuery READ searchQuery WRITE setSearchQuery NOTIFY searchQueryChanged)
    Q_PROPERTY(int categoryIndex READ categoryIndex WRITE setCategoryIndex NOTIFY categoryIndexChanged)

public:
    explicit ReferenceFilterModel(QObject *parent = nullptr);

    QString searchQuery() const { return m_searchQuery; }
    void setSearchQuery(const QString &query);

    int categoryIndex() const { return m_categoryIndex; }
    void setCategoryIndex(int index);

signals:
    void searchQueryChanged();
    void categoryIndexChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

private:
    bool matchesCategory(const QString &entryType) const;
    bool matchesSearch(int sourceRow, const QModelIndex &sourceParent) const;

    QString m_searchQuery;
    int m_categoryIndex = 0;
};

#endif // REFERENCEFILTERMODEL_H
