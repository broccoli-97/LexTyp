#include "ReferenceFilterModel.h"

#include "ReferenceLibrary.h"

ReferenceFilterModel::ReferenceFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent) {}

void ReferenceFilterModel::setSearchQuery(const QString &query) {
    if (m_searchQuery == query)
        return;
    m_searchQuery = query;
    emit searchQueryChanged();
    invalidateFilter();
}

void ReferenceFilterModel::setCategoryIndex(int index) {
    if (m_categoryIndex == index)
        return;
    m_categoryIndex = index;
    emit categoryIndexChanged();
    invalidateFilter();
}

bool ReferenceFilterModel::matchesCategory(const QString &entryType) const {
    switch (m_categoryIndex) {
        case 0:  return true;                                     // All
        case 1:  return entryType == QLatin1String("case");       // Cases
        case 2:  return entryType == QLatin1String("legislation"); // Statutes
        case 3:  return entryType == QLatin1String("book");       // Books
        case 4:                                                   // Academic
            return entryType != QLatin1String("case") &&
                   entryType != QLatin1String("legislation") &&
                   entryType != QLatin1String("book");
        default: return true;
    }
}

bool ReferenceFilterModel::matchesSearch(int sourceRow, const QModelIndex &sourceParent) const {
    if (m_searchQuery.isEmpty())
        return true;

    auto idx = [&](int role) {
        return sourceModel()->data(sourceModel()->index(sourceRow, 0, sourceParent), role).toString();
    };

    auto contains = [&](const QString &text) {
        return text.contains(m_searchQuery, Qt::CaseInsensitive);
    };

    // Search across key, title, author, year
    return contains(idx(ReferenceLibrary::KeyRole)) ||
           contains(idx(ReferenceLibrary::TitleRole)) ||
           contains(idx(ReferenceLibrary::AuthorRole)) ||
           contains(idx(ReferenceLibrary::YearRole));
}

bool ReferenceFilterModel::filterAcceptsRow(int sourceRow,
                                            const QModelIndex &sourceParent) const {
    QString entryType = sourceModel()
                            ->data(sourceModel()->index(sourceRow, 0, sourceParent),
                                   ReferenceLibrary::TypeRole)
                            .toString();

    return matchesCategory(entryType) && matchesSearch(sourceRow, sourceParent);
}
