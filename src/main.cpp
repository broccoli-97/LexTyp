#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QUrl>

#include "PdfManager.h"

int main(int argc, char *argv[])
{
    // Use Basic style to ensure custom control backgrounds work on all platforms
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    QApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("LexTyp"));
    app.setApplicationVersion(QStringLiteral("0.1.0"));
    app.setOrganizationName(QStringLiteral("LexTyp"));

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("qrc:/"));

    // Register PDF page image provider (PdfManager will connect its document)
    auto *pdfProvider = new PdfPageImageProvider;
    PdfPageImageProvider::setGlobalInstance(pdfProvider);
    engine.addImageProvider(QStringLiteral("pdf"), pdfProvider);

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        []() { QCoreApplication::exit(1); }, Qt::QueuedConnection);

    engine.load(QUrl(QStringLiteral("qrc:/LexTyp/qml/Main.qml")));

    return app.exec();
}
