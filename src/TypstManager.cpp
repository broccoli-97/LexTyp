#include "TypstManager.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QStandardPaths>

TypstManager::TypstManager(QObject *parent)
    : QObject(parent)
{
}

bool TypstManager::compiling() const { return m_compiling; }
QString TypstManager::lastError() const { return m_lastError; }
QString TypstManager::lastPdfPath() const { return m_lastPdfPath; }
qint64 TypstManager::lastDuration() const { return m_lastDuration; }

QString TypstManager::resolveTypstPath() const
{
    // Check next to the application binary first
    QString appDirPath = QCoreApplication::applicationDirPath()
                         + QStringLiteral("/resources/bin/typst");
    if (QFile::exists(appDirPath))
        return appDirPath;

    // Check the source tree location (useful during development)
    QString srcPath = QCoreApplication::applicationDirPath()
                      + QStringLiteral("/../../resources/bin/typst");
    QString canonical = QDir(srcPath).canonicalPath();
    if (!canonical.isEmpty() && QFile::exists(canonical))
        return canonical;

    // Fallback to system PATH
    QString systemPath = QStandardPaths::findExecutable(QStringLiteral("typst"));
    if (!systemPath.isEmpty())
        return systemPath;

    return {};
}

void TypstManager::compile(const QString &typContent)
{
    if (m_compiling)
        return;

    QString typstBin = resolveTypstPath();
    if (typstBin.isEmpty()) {
        m_lastError = QStringLiteral("Typst binary not found");
        emit lastErrorChanged();
        emit compilationFailed(m_lastError);
        return;
    }

    // Write content to a build output directory next to the executable
    QString outDir = QCoreApplication::applicationDirPath() + QStringLiteral("/output");
    QDir().mkpath(outDir);

    QString inputPath = outDir + QStringLiteral("/input.typ");
    QString outputPath = outDir + QStringLiteral("/output.pdf");

    QFile inputFile(inputPath);
    if (!inputFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        m_lastError = QStringLiteral("Failed to write temp file: ") + inputFile.errorString();
        emit lastErrorChanged();
        emit compilationFailed(m_lastError);
        return;
    }
    inputFile.write(typContent.toUtf8());
    inputFile.close();

    m_compiling = true;
    emit compilingChanged();

    m_timer.start();

    auto *process = new QProcess(this);
    process->setProgram(typstBin);
    process->setArguments({QStringLiteral("compile"), inputPath, outputPath});

    connect(process, &QProcess::finished, this,
            [this, process, outputPath](int exitCode, QProcess::ExitStatus) {
        m_lastDuration = m_timer.elapsed();
        emit lastDurationChanged();

        m_compiling = false;
        emit compilingChanged();

        if (exitCode == 0) {
            m_lastError.clear();
            emit lastErrorChanged();

            m_lastPdfPath = outputPath;
            emit lastPdfPathChanged();
            emit compilationFinished(outputPath);
        } else {
            m_lastError = QString::fromUtf8(process->readAllStandardError());
            if (m_lastError.isEmpty())
                m_lastError = QStringLiteral("Typst exited with code %1").arg(exitCode);
            emit lastErrorChanged();
            emit compilationFailed(m_lastError);
        }

        process->deleteLater();
    });

    connect(process, &QProcess::errorOccurred, this,
            [this, process](QProcess::ProcessError error) {
        Q_UNUSED(error)
        m_lastDuration = m_timer.elapsed();
        emit lastDurationChanged();

        m_compiling = false;
        emit compilingChanged();

        m_lastError = QStringLiteral("Process error: ") + process->errorString();
        emit lastErrorChanged();
        emit compilationFailed(m_lastError);

        process->deleteLater();
    });

    process->start();
}
