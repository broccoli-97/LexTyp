#ifndef CITATIONSTYLEREGISTRY_H
#define CITATIONSTYLEREGISTRY_H

#include <QHash>
#include <QString>
#include <memory>

class CitationFormatter;

class CitationStyleRegistry
{
public:
    static CitationStyleRegistry &instance();

    // Register a formatter under one or more alias names
    void registerFormatter(const QString &name, std::shared_ptr<CitationFormatter> formatter);
    void registerAlias(const QString &alias, const QString &canonicalName);

    // Resolve a style name (or alias) to a formatter.
    // Returns the default (OSCOLA) if not found.
    std::shared_ptr<CitationFormatter> formatter(const QString &styleName) const;

    // The default formatter (OSCOLA)
    std::shared_ptr<CitationFormatter> defaultFormatter() const;

private:
    CitationStyleRegistry();

    void registerBuiltins();

    QHash<QString, std::shared_ptr<CitationFormatter>> m_formatters;
    QHash<QString, QString> m_aliases; // alias → canonical name
    std::shared_ptr<CitationFormatter> m_default;
};

#endif // CITATIONSTYLEREGISTRY_H
