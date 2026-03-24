#include "TypstSerializer.h"

#include "ast/DocumentNode.h"
#include "ast/TitleNode.h"
#include "ast/ParagraphNode.h"
#include "ast/CitationNode.h"
#include "ast/SectionNode.h"
#include "bib/BibParser.h"
#include "oscola/OscolaFormatter.h"

#include <QRegularExpression>

static QString processInlineCitations(const QString &text,
                                      ReferenceLibrary *library,
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
                QString footnoteText = OscolaFormatter::formatFootnote(
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
                                   ReferenceLibrary *library)
{
    QString output;
    QVector<CitationHistoryEntry> citationHistory;
    int footnoteCounter = 0;

    for (const auto &node : nodes) {
        switch (node->type()) {
        case NodeType::Title: {
            auto *title = static_cast<TitleNode *>(node.get());
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
                content = processInlineCitations(content, library, citationHistory, footnoteCounter);
            }
            output += content;
            output += QStringLiteral("\n\n");
            break;
        }
        case NodeType::Citation: {
            auto *cite = static_cast<CitationNode *>(node.get());
            ++footnoteCounter;

            if (library && !cite->key().isEmpty()) {
                BibEntry entry = library->findEntry(cite->key());
                if (!entry.key.isEmpty()) {
                    // Use OSCOLA formatting with footnote
                    QString pinpoint = cite->suffix();
                    QString footnoteText = OscolaFormatter::formatFootnote(
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
            output += QStringLiteral("// Section: ");
            output += node->content();
            output += QLatin1Char('\n');
            break;
        }
        }
    }

    return output;
}
