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

QString TypstManager::statusText() const {
    if (m_compiling)
        return QStringLiteral("Compiling\u2026");
    if (!m_lastError.isEmpty())
        return QStringLiteral("Error");
    if (!m_lastPdfPath.isEmpty())
        return QStringLiteral("Compiled in %1ms").arg(m_lastDuration);
    return QStringLiteral("Ready");
}

QString TypstManager::compilationDetail() const {
    QString msg;
    if (m_compiling) {
        msg = QStringLiteral("Status: Compiling...\n");
    } else if (!m_lastError.isEmpty()) {
        msg = QStringLiteral("Status: Error\n");
    } else {
        msg = QStringLiteral("Status: Success\n");
    }
    if (m_lastDuration > 0)
        msg += QStringLiteral("Duration: %1s\n").arg(m_lastDuration / 1000.0, 0, 'f', 2);
    if (!m_lastError.isEmpty())
        msg += QStringLiteral("\nError Message:\n") + m_lastError;
    return msg;
}

QString TypstManager::resolveTypstPath() const
{
    // Platform-specific executable suffix
#ifdef Q_OS_WIN
    const QString exe = QStringLiteral(".exe");
#else
    const QString exe;
#endif

    // Check next to the application binary first
    QString appDirPath = QCoreApplication::applicationDirPath()
                         + QStringLiteral("/resources/bin/typst") + exe;
    if (QFile::exists(appDirPath))
        return appDirPath;

    // Check the source tree location (useful during development)
    QString srcPath = QCoreApplication::applicationDirPath()
                      + QStringLiteral("/../../resources/bin/typst") + exe;
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
        emit statusTextChanged();
        emit compilationDetailChanged();
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
    emit statusTextChanged();

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

        emit statusTextChanged();
        emit compilationDetailChanged();

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
        emit statusTextChanged();
        emit compilationDetailChanged();

        process->deleteLater();
    });

    process->start();
}
