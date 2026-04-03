#include "CitationRangeHelper.h"

#include <QRegularExpression>
#include <Qt>

CitationRangeHelper::CitationRangeHelper(QObject *parent)
    : QObject(parent) {}

QVariantList CitationRangeHelper::parseCiteKeys(const QString &text) const {
    static const QRegularExpression re(QStringLiteral("@([\\w][\\w-]*)"));

    QVariantList results;
    auto it = re.globalMatch(text);
    while (it.hasNext()) {
        auto match = it.next();
        int startPos = match.capturedStart(0);
        int endPos = match.capturedEnd(0);

        // snapEnd extends past trailing space so cursor lands beyond
        int snapEnd = endPos;
        if (snapEnd < text.length() && text.at(snapEnd) == QLatin1Char(' '))
            snapEnd++;

        QVariantMap entry;
        entry[QStringLiteral("start")] = startPos;
        entry[QStringLiteral("end")] = endPos;
        entry[QStringLiteral("snapEnd")] = snapEnd;
        entry[QStringLiteral("key")] = match.captured(1);
        entry[QStringLiteral("display")] = QStringLiteral("@") + match.captured(1);
        results.append(entry);
    }
    return results;
}

QVariantMap CitationRangeHelper::citationAt(const QVariantList &ranges, int pos) const {
    for (const auto &v : ranges) {
        auto r = v.toMap();
        int start = r[QStringLiteral("start")].toInt();
        int snapEnd = r[QStringLiteral("snapEnd")].toInt();
        if (pos > start && pos < snapEnd)
            return r;
    }
    return {};
}

QVariantMap CitationRangeHelper::citationStartingAt(const QVariantList &ranges, int pos) const {
    for (const auto &v : ranges) {
        auto r = v.toMap();
        if (r[QStringLiteral("start")].toInt() == pos)
            return r;
    }
    return {};
}

QVariantMap CitationRangeHelper::citationEndingAt(const QVariantList &ranges, int pos) const {
    for (const auto &v : ranges) {
        auto r = v.toMap();
        if (r[QStringLiteral("end")].toInt() == pos)
            return r;
    }
    return {};
}

QVariantMap CitationRangeHelper::citationSnapEndAt(const QVariantList &ranges, int pos) const {
    for (const auto &v : ranges) {
        auto r = v.toMap();
        int end = r[QStringLiteral("end")].toInt();
        int snapEnd = r[QStringLiteral("snapEnd")].toInt();
        if (snapEnd == pos && snapEnd != end)
            return r;
    }
    return {};
}

QVariantMap CitationRangeHelper::handleKeyAction(const QVariantList &ranges, int cursorPos,
                                                 int key, const QString &eventText) const {
    QVariantMap result;
    result[QStringLiteral("action")] = QStringLiteral("none");

    // Character input check: block typing inside or extending a citation
    if (!eventText.isEmpty() && key == -1) {
        auto citInside = citationAt(ranges, cursorPos);
        if (!citInside.isEmpty()) {
            result[QStringLiteral("action")] = QStringLiteral("block");
            return result;
        }
        auto citAtEnd = citationEndingAt(ranges, cursorPos);
        if (!citAtEnd.isEmpty()) {
            QChar ch = eventText.at(0);
            if (ch.isLetterOrNumber() || ch == QLatin1Char('_') || ch == QLatin1Char('-')) {
                result[QStringLiteral("action")] = QStringLiteral("block");
                return result;
            }
        }
        return result;
    }

    // Also block regular character input that lands inside a citation
    if (!eventText.isEmpty()) {
        auto citInside = citationAt(ranges, cursorPos);
        if (!citInside.isEmpty()) {
            result[QStringLiteral("action")] = QStringLiteral("block");
            return result;
        }
        auto citAtEnd = citationEndingAt(ranges, cursorPos);
        if (!citAtEnd.isEmpty()) {
            QChar ch = eventText.at(0);
            if (ch.isLetterOrNumber() || ch == QLatin1Char('_') || ch == QLatin1Char('-')) {
                result[QStringLiteral("action")] = QStringLiteral("block");
                return result;
            }
        }
    }

    // Arrow Right: skip over citation
    if (key == Qt::Key_Right) {
        auto cit = citationStartingAt(ranges, cursorPos);
        if (!cit.isEmpty()) {
            result[QStringLiteral("action")] = QStringLiteral("move");
            result[QStringLiteral("cursorPos")] = cit[QStringLiteral("snapEnd")].toInt();
            return result;
        }
    }

    // Arrow Left: skip back over citation
    if (key == Qt::Key_Left) {
        auto citEnd = citationEndingAt(ranges, cursorPos);
        if (!citEnd.isEmpty()) {
            result[QStringLiteral("action")] = QStringLiteral("move");
            result[QStringLiteral("cursorPos")] = citEnd[QStringLiteral("start")].toInt();
            return result;
        }
        auto citSnap = citationSnapEndAt(ranges, cursorPos);
        if (!citSnap.isEmpty()) {
            result[QStringLiteral("action")] = QStringLiteral("move");
            result[QStringLiteral("cursorPos")] = citSnap[QStringLiteral("start")].toInt();
            return result;
        }
    }

    // Backspace: delete entire citation
    if (key == Qt::Key_Backspace) {
        auto cit = citationEndingAt(ranges, cursorPos);
        if (cit.isEmpty())
            cit = citationSnapEndAt(ranges, cursorPos);
        if (cit.isEmpty())
            cit = citationAt(ranges, cursorPos);
        if (!cit.isEmpty()) {
            result[QStringLiteral("action")] = QStringLiteral("delete");
            result[QStringLiteral("deleteStart")] = cit[QStringLiteral("start")].toInt();
            result[QStringLiteral("deleteEnd")] = cit[QStringLiteral("end")].toInt();
            return result;
        }
    }

    // Delete key: delete entire citation
    if (key == Qt::Key_Delete) {
        auto cit = citationStartingAt(ranges, cursorPos);
        if (cit.isEmpty())
            cit = citationAt(ranges, cursorPos);
        if (!cit.isEmpty()) {
            result[QStringLiteral("action")] = QStringLiteral("delete");
            result[QStringLiteral("deleteStart")] = cit[QStringLiteral("start")].toInt();
            result[QStringLiteral("deleteEnd")] = cit[QStringLiteral("end")].toInt();
            return result;
        }
    }

    return result;
}
