#ifndef BIBENTRY_H
#define BIBENTRY_H

#include <QMap>
#include <QString>

struct BibEntry {
    QString type; // BibTeX entry type: "article", "book", "inproceedings", "case", "legislation", etc.
    QString key;
    QMap<QString, QString> fields;

    QString field(const QString &name) const { return fields.value(name); }
};

#endif // BIBENTRY_H
