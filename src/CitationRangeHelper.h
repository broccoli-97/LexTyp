#ifndef CITATIONRANGEHELPER_H
#define CITATIONRANGEHELPER_H

#include <QObject>
#include <QQmlEngine>
#include <QVariantList>
#include <QVariantMap>

class CitationRangeHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit CitationRangeHelper(QObject *parent = nullptr);

    // Parse @key patterns from text. Returns [{start, end, snapEnd, key, display}, ...]
    Q_INVOKABLE QVariantList parseCiteKeys(const QString &text) const;

    // Boundary lookups on a previously-parsed ranges list.
    // Returns matching range map, or empty map if none found.
    Q_INVOKABLE QVariantMap citationAt(const QVariantList &ranges, int pos) const;
    Q_INVOKABLE QVariantMap citationStartingAt(const QVariantList &ranges, int pos) const;
    Q_INVOKABLE QVariantMap citationEndingAt(const QVariantList &ranges, int pos) const;
    Q_INVOKABLE QVariantMap citationSnapEndAt(const QVariantList &ranges, int pos) const;

    // Keyboard action dispatcher for citation-aware editing.
    // key: Qt::Key value (e.g. Qt::Key_Left), or -1 for character input check.
    // eventText: the text of the key event (for character type detection).
    // Returns {action: "none"|"block"|"move"|"delete",
    //          cursorPos: int (for "move"), deleteStart/deleteEnd: int (for "delete")}
    Q_INVOKABLE QVariantMap handleKeyAction(const QVariantList &ranges, int cursorPos,
                                            int key, const QString &eventText) const;
};

#endif // CITATIONRANGEHELPER_H
