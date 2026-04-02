#include "CitationStyleRegistry.h"
#include "CitationFormatter.h"

#include "oscola/OscolaFormatter.h"
#include "citation/ApaFormatter.h"
#include "citation/HarvardFormatter.h"
#include "citation/ChicagoFormatter.h"
#include "citation/IeeeFormatter.h"
#include "citation/PlainFormatter.h"

#include <QDebug>

CitationStyleRegistry &CitationStyleRegistry::instance()
{
    static CitationStyleRegistry registry;
    return registry;
}

CitationStyleRegistry::CitationStyleRegistry()
{
    registerBuiltins();
}

void CitationStyleRegistry::registerBuiltins()
{
    // OSCOLA (default)
    auto oscola = std::make_shared<OscolaFormatter>();
    m_default = oscola;
    registerFormatter(QStringLiteral("oscola"), oscola);

    // APA
    auto apa = std::make_shared<ApaFormatter>();
    registerFormatter(QStringLiteral("apa"), apa);
    registerAlias(QStringLiteral("apalike"), QStringLiteral("apa"));
    registerAlias(QStringLiteral("apacite"), QStringLiteral("apa"));

    // Harvard
    auto harvard = std::make_shared<HarvardFormatter>();
    registerFormatter(QStringLiteral("harvard"), harvard);
    registerAlias(QStringLiteral("agsm"), QStringLiteral("harvard"));
    registerAlias(QStringLiteral("dcu"), QStringLiteral("harvard"));

    // Chicago
    auto chicago = std::make_shared<ChicagoFormatter>();
    registerFormatter(QStringLiteral("chicago"), chicago);
    registerAlias(QStringLiteral("chicagoa"), QStringLiteral("chicago"));

    // IEEE
    auto ieee = std::make_shared<IeeeFormatter>();
    registerFormatter(QStringLiteral("ieee"), ieee);
    registerAlias(QStringLiteral("ieeetr"), QStringLiteral("ieee"));
    registerAlias(QStringLiteral("IEEEtran"), QStringLiteral("ieee"));

    // Plain
    auto plain = std::make_shared<PlainFormatter>();
    registerFormatter(QStringLiteral("plain"), plain);
    registerAlias(QStringLiteral("plainnat"), QStringLiteral("plain"));
    registerAlias(QStringLiteral("unsrt"), QStringLiteral("plain"));
    registerAlias(QStringLiteral("abbrv"), QStringLiteral("plain"));
    registerAlias(QStringLiteral("alpha"), QStringLiteral("plain"));
}

void CitationStyleRegistry::registerFormatter(const QString &name,
                                               std::shared_ptr<CitationFormatter> formatter)
{
    m_formatters.insert(name.toLower(), std::move(formatter));
}

void CitationStyleRegistry::registerAlias(const QString &alias, const QString &canonicalName)
{
    m_aliases.insert(alias.toLower(), canonicalName.toLower());
}

std::shared_ptr<CitationFormatter> CitationStyleRegistry::formatter(const QString &styleName) const
{
    QString key = styleName.toLower();

    // Direct lookup
    auto it = m_formatters.find(key);
    if (it != m_formatters.end())
        return it.value();

    // Alias lookup
    auto aliasIt = m_aliases.find(key);
    if (aliasIt != m_aliases.end()) {
        auto it2 = m_formatters.find(aliasIt.value());
        if (it2 != m_formatters.end())
            return it2.value();
    }

    qWarning() << "Unknown citation style:" << styleName << "- falling back to OSCOLA";
    return m_default;
}

std::shared_ptr<CitationFormatter> CitationStyleRegistry::defaultFormatter() const
{
    return m_default;
}

QStringList CitationStyleRegistry::styleNames() const
{
    QStringList names = m_formatters.keys();
    names.sort();
    return names;
}
