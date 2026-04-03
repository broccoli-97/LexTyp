#include "BibEntryHelper.h"

BibEntryHelper::BibEntryHelper(QObject *parent)
    : QObject(parent) {}

const QHash<QString, QString> &BibEntryHelper::fieldLabels() {
    static const QHash<QString, QString> labels = {
        {QStringLiteral("title"),        QStringLiteral("Title")},
        {QStringLiteral("author"),       QStringLiteral("Author")},
        {QStringLiteral("year"),         QStringLiteral("Year")},
        {QStringLiteral("journal"),      QStringLiteral("Journal")},
        {QStringLiteral("volume"),       QStringLiteral("Volume")},
        {QStringLiteral("number"),       QStringLiteral("Number")},
        {QStringLiteral("pages"),        QStringLiteral("Pages")},
        {QStringLiteral("publisher"),    QStringLiteral("Publisher")},
        {QStringLiteral("address"),      QStringLiteral("Address")},
        {QStringLiteral("edition"),      QStringLiteral("Edition")},
        {QStringLiteral("editor"),       QStringLiteral("Editor")},
        {QStringLiteral("booktitle"),    QStringLiteral("Book Title")},
        {QStringLiteral("series"),       QStringLiteral("Series")},
        {QStringLiteral("chapter"),      QStringLiteral("Chapter")},
        {QStringLiteral("school"),       QStringLiteral("School")},
        {QStringLiteral("institution"),  QStringLiteral("Institution")},
        {QStringLiteral("court"),        QStringLiteral("Court")},
        {QStringLiteral("doi"),          QStringLiteral("DOI")},
        {QStringLiteral("url"),          QStringLiteral("URL")},
        {QStringLiteral("note"),         QStringLiteral("Note")},
        {QStringLiteral("abstract"),     QStringLiteral("Abstract")},
        {QStringLiteral("keywords"),     QStringLiteral("Keywords")},
        {QStringLiteral("isbn"),         QStringLiteral("ISBN")},
        {QStringLiteral("issn"),         QStringLiteral("ISSN")},
        {QStringLiteral("howpublished"), QStringLiteral("How Published")},
        {QStringLiteral("month"),        QStringLiteral("Month")},
    };
    return labels;
}

QString BibEntryHelper::fieldLabel(const QString &key) const {
    auto it = fieldLabels().find(key);
    if (it != fieldLabels().end())
        return it.value();
    if (key.isEmpty())
        return key;
    return key.at(0).toUpper() + key.mid(1);
}

bool BibEntryHelper::isAcademicType(const QString &entryType) const {
    return entryType != QLatin1String("case") &&
           entryType != QLatin1String("legislation") &&
           entryType != QLatin1String("book");
}

QVariantMap BibEntryHelper::badgeInfo(const QString &entryType) const {
    struct Badge {
        const char *label;
        const char *bg;
        const char *fg;
    };

    static const QHash<QString, Badge> badges = {
        {QStringLiteral("case"),          {"Case",       "#FFF3E0", "#E65100"}},
        {QStringLiteral("legislation"),   {"Statute",    "#E8F5E9", "#2E7D32"}},
        {QStringLiteral("book"),          {"Book",       "#E3F2FD", "#1565C0"}},
        {QStringLiteral("article"),       {"Article",    "#F3E5F5", "#6A1B9A"}},
        {QStringLiteral("inproceedings"), {"Conference", "#FFF8E1", "#F57F17"}},
        {QStringLiteral("conference"),    {"Conference", "#FFF8E1", "#F57F17"}},
        {QStringLiteral("incollection"),  {"Chapter",    "#E0F2F1", "#00695C"}},
        {QStringLiteral("inbook"),        {"Chapter",    "#E0F2F1", "#00695C"}},
        {QStringLiteral("phdthesis"),     {"PhD Thesis", "#FCE4EC", "#880E4F"}},
        {QStringLiteral("mastersthesis"), {"MA Thesis",  "#FCE4EC", "#880E4F"}},
        {QStringLiteral("techreport"),    {"Report",     "#EFEBE9", "#4E342E"}},
        {QStringLiteral("misc"),          {"Misc",       "#ECEFF1", "#37474F"}},
        {QStringLiteral("online"),        {"Online",     "#E8EAF6", "#283593"}},
    };

    auto it = badges.find(entryType);
    if (it != badges.end()) {
        return {{QStringLiteral("label"), QString::fromLatin1(it->label)},
                {QStringLiteral("bg"),    QString::fromLatin1(it->bg)},
                {QStringLiteral("fg"),    QString::fromLatin1(it->fg)}};
    }

    return {{QStringLiteral("label"), entryType},
            {QStringLiteral("bg"),    QStringLiteral("#ECEFF1")},
            {QStringLiteral("fg"),    QStringLiteral("#37474F")}};
}

QString BibEntryHelper::secondaryInfo(const QString &entryType, const QVariantMap &fields) const {
    auto f = [&](const QString &key) -> QString {
        return fields.value(key).toString();
    };

    QStringList parts;

    if (entryType == QLatin1String("case")) {
        if (!f(QStringLiteral("year")).isEmpty())
            parts << QStringLiteral("[%1]").arg(f(QStringLiteral("year")));
        if (!f(QStringLiteral("court")).isEmpty())
            parts << f(QStringLiteral("court"));
        if (!f(QStringLiteral("number")).isEmpty())
            parts << f(QStringLiteral("number"));
        return parts.join(QLatin1Char(' '));
    }

    if (entryType == QLatin1String("legislation")) {
        return f(QStringLiteral("year"));
    }

    if (entryType == QLatin1String("article")) {
        if (!f(QStringLiteral("author")).isEmpty())
            parts << f(QStringLiteral("author"));
        if (!f(QStringLiteral("journal")).isEmpty())
            parts << f(QStringLiteral("journal"));
        if (!f(QStringLiteral("volume")).isEmpty())
            parts << QStringLiteral("vol. %1").arg(f(QStringLiteral("volume")));
        if (!f(QStringLiteral("year")).isEmpty())
            parts << QStringLiteral("(%1)").arg(f(QStringLiteral("year")));
        return parts.join(QStringLiteral(", "));
    }

    if (entryType == QLatin1String("inproceedings") || entryType == QLatin1String("conference") ||
        entryType == QLatin1String("incollection") || entryType == QLatin1String("inbook")) {
        if (!f(QStringLiteral("author")).isEmpty())
            parts << f(QStringLiteral("author"));
        if (!f(QStringLiteral("booktitle")).isEmpty())
            parts << QStringLiteral("in: %1").arg(f(QStringLiteral("booktitle")));
        if (!f(QStringLiteral("year")).isEmpty())
            parts << QStringLiteral("(%1)").arg(f(QStringLiteral("year")));
        return parts.join(QStringLiteral(", "));
    }

    if (entryType == QLatin1String("phdthesis") || entryType == QLatin1String("mastersthesis")) {
        if (!f(QStringLiteral("author")).isEmpty())
            parts << f(QStringLiteral("author"));
        if (!f(QStringLiteral("school")).isEmpty())
            parts << f(QStringLiteral("school"));
        if (!f(QStringLiteral("year")).isEmpty())
            parts << QStringLiteral("(%1)").arg(f(QStringLiteral("year")));
        return parts.join(QStringLiteral(", "));
    }

    // Default: book, techreport, misc, online, etc.
    if (!f(QStringLiteral("author")).isEmpty())
        parts << f(QStringLiteral("author"));
    if (!f(QStringLiteral("publisher")).isEmpty())
        parts << f(QStringLiteral("publisher"));
    if (!f(QStringLiteral("year")).isEmpty())
        parts << f(QStringLiteral("year"));
    return parts.join(QStringLiteral(", "));
}

QString BibEntryHelper::displayTitle(const QString &entryType, const QVariantMap &fields,
                                     const QString &key) const {
    QString title = fields.value(QStringLiteral("title")).toString();
    if (entryType == QLatin1String("case")) {
        QString author = fields.value(QStringLiteral("author")).toString();
        if (!author.isEmpty())
            return author;
    }
    return title.isEmpty() ? key : title;
}
