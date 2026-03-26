#include "TypstSerializer.h"

#include "ast/DocumentNode.h"
#include "ast/TitleNode.h"
#include "ast/ParagraphNode.h"
#include "ast/CitationNode.h"
#include "ast/SectionNode.h"
#include "bib/ReferenceLibrary.h"
#include "citation/CitationFormatter.h"

#include <QRegularExpression>

static QString processInlineCitations(const QString &text,
                                      const ReferenceLibrary *library,
                                      const CitationFormatter &formatter,
                                      QVector<CitationHistoryEntry> &citationHistory,
                                      int &footnoteCounter)
{
    static const QRegularExpression rx(QStringLiteral("@([\\w][\\w-]*)"));
    QString result;
    qsizetype lastEnd = 0;
    auto it = rx.globalMatch(text);

    while (it.hasNext()) {
        auto match = it.next();
        result += text.mid(lastEnd, match.capturedStart() - lastEnd);

        QString key = match.captured(1);
        bool replaced = false;

        if (library && !key.isEmpty()) {
            BibEntry entry = library->findEntry(key);
            if (!entry.key.isEmpty()) {
                ++footnoteCounter;
                QString footnoteText = formatter.formatFootnote(
                    entry, QString(), citationHistory, footnoteCounter);
                result += QStringLiteral("#footnote[") + footnoteText + QStringLiteral("]");
                citationHistory.append({key, footnoteCounter});
                replaced = true;
            }
        }

        if (!replaced) {
            // Leave as-is (Typst native cite or unresolved key)
            result += match.captured(0);
        }

        lastEnd = match.capturedEnd();
    }

    result += text.mid(lastEnd);
    return result;
}

QString TypstSerializer::serialize(const QVector<std::shared_ptr<DocumentNode>> &nodes,
                                   const ReferenceLibrary *library,
                                   const CitationFormatter &formatter)
{
    QString output;
    
    // Default Document Setup
    output += QStringLiteral("#set page(paper: \"a4\", margin: 2cm)\n");
    output += QStringLiteral("#set text(font: (\"DejaVu Sans\", \"Noto Serif\"), size: 11pt)\n");
    output += QStringLiteral("#set par(justify: true, leading: 0.65em)\n\n");

    QVector<CitationHistoryEntry> citationHistory;
    int footnoteCounter = 0;

    for (const auto &node : nodes) {
        switch (node->type()) {
        case NodeType::Title: {
            auto *title = node->as<TitleNode>();
            if (!title) break;
            // Typst heading: "= " for level 1, "== " for level 2, etc.
            output += QString(title->level(), QLatin1Char('='));
            output += QLatin1Char(' ');
            output += title->content();
            output += QLatin1Char('\n');
            break;
        }
        case NodeType::Paragraph: {
            QString content = node->content();
            if (content.contains(QLatin1Char('@'))) {
                content = processInlineCitations(content, library, formatter, citationHistory, footnoteCounter);
            }
            // Wrap paragraph in a block to ensure 100% width and correct wrapping
            output += QStringLiteral("#block(width: 100%)[");
            output += content;
            output += QStringLiteral("]");
            output += QStringLiteral("\n\n");
            break;
        }
        case NodeType::Citation: {
            auto *cite = node->as<CitationNode>();
            if (!cite) break;
            ++footnoteCounter;

            if (library && !cite->key().isEmpty()) {
                BibEntry entry = library->findEntry(cite->key());
                if (!entry.key.isEmpty()) {
                    QString pinpoint = cite->suffix();
                    QString footnoteText = formatter.formatFootnote(
                        entry, pinpoint, citationHistory, footnoteCounter);

                    if (!cite->prefix().isEmpty()) {
                        output += cite->prefix();
                        output += QLatin1Char(' ');
                    }
                    output += QStringLiteral("#footnote[");
                    output += footnoteText;
                    output += QStringLiteral("]");
                    output += QStringLiteral("\n\n");

                    citationHistory.append({cite->key(), footnoteCounter});
                    break;
                }
            }

            // Fallback: no library or entry not found — use original #cite syntax
            if (!cite->prefix().isEmpty()) {
                output += cite->prefix();
                output += QLatin1Char(' ');
            }
            output += QStringLiteral("#cite(<");
            output += cite->key();
            output += QStringLiteral(">)");
            if (!cite->suffix().isEmpty()) {
                output += QLatin1Char(' ');
                output += cite->suffix();
            }
            output += QStringLiteral("\n\n");
            break;
        }
        case NodeType::Section: {
            output += QStringLiteral("== ");
            output += node->content();
            output += QLatin1Char('\n');
            break;
        }
        }
    }

    return output;
}
