#include "PdfManager.h"

#include <QPdfDocumentRenderOptions>
#include <QFile>

// --- PdfPageImageProvider ---

PdfPageImageProvider *PdfPageImageProvider::s_instance = nullptr;

PdfPageImageProvider::PdfPageImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}

PdfPageImageProvider *PdfPageImageProvider::globalInstance()
{
    return s_instance;
}

void PdfPageImageProvider::setGlobalInstance(PdfPageImageProvider *provider)
{
    s_instance = provider;
}

QImage PdfPageImageProvider::requestImage(const QString &id, QSize *size,
                                          const QSize &requestedSize)
{
    // id format: "pageNum?v=version" — strip query part
    int queryIdx = id.indexOf(QLatin1Char('?'));
    int page = (queryIdx >= 0 ? id.left(queryIdx) : id).toInt();

    if (!m_doc || m_doc->status() != QPdfDocument::Status::Ready
        || page < 0 || page >= m_doc->pageCount()) {
        QImage empty(1, 1, QImage::Format_ARGB32);
        empty.fill(Qt::white);
        if (size)
            *size = empty.size();
        return empty;
    }

    QSizeF pageSize = m_doc->pagePointSize(page);

    // Scale to requested width, or use default 150 DPI
    qreal dpi = 150.0;
    QSize renderSize;
    if (requestedSize.width() > 0) {
        qreal scale = requestedSize.width() / pageSize.width();
        renderSize = QSize(requestedSize.width(),
                           qRound(pageSize.height() * scale));
    } else {
        renderSize = QSize(qRound(pageSize.width() * dpi / 72.0),
                           qRound(pageSize.height() * dpi / 72.0));
    }

    QImage image = m_doc->render(page, renderSize);

    if (size)
        *size = image.size();

    return image;
}

void PdfPageImageProvider::setDocument(QPdfDocument *doc)
{
    m_doc = doc;
}

// --- PdfManager ---

PdfManager::PdfManager(QObject *parent)
    : QObject(parent)
{
    // Connect this instance's document to the shared image provider
    if (auto *provider = PdfPageImageProvider::globalInstance())
        provider->setDocument(&m_document);
    else
        qWarning("PdfManager: PdfPageImageProvider global instance not set");

    connect(&m_document, &QPdfDocument::pageCountChanged, this, [this]() {
        emit pageCountChanged();
    });

    connect(&m_document, &QPdfDocument::statusChanged, this, [this](QPdfDocument::Status status) {
        if (status == QPdfDocument::Status::Error) {
            m_errorMessage = QStringLiteral("Failed to load PDF");
            emit errorMessageChanged();
        } else if (status == QPdfDocument::Status::Ready) {
            m_errorMessage.clear();
            emit errorMessageChanged();
        }
    });
}

int PdfManager::pageCount() const
{
    return m_document.pageCount();
}

int PdfManager::version() const
{
    return m_version;
}

QString PdfManager::errorMessage() const
{
    return m_errorMessage;
}

void PdfManager::load(const QString &filePath)
{
    if (!QFile::exists(filePath)) {
        m_errorMessage = QStringLiteral("PDF file not found: ") + filePath;
        emit errorMessageChanged();
        return;
    }

    m_document.close();
    m_document.load(filePath);

    // Bump version to bust QML image cache
    m_version++;
    emit versionChanged();
    emit documentLoaded();
}

QSizeF PdfManager::pageSize(int page) const
{
    if (page < 0 || page >= m_document.pageCount())
        return QSizeF();
    return m_document.pagePointSize(page);
}

void PdfManager::setZoomLevel(qreal level) {
    level = qBound(kZoomMin, level, kZoomMax);
    if (qFuzzyCompare(m_zoomLevel, level))
        return;
    m_zoomLevel = level;
    emit zoomLevelChanged();
}

QString PdfManager::pageCountText() const {
    int count = m_document.pageCount();
    if (count == 0)
        return QString();
    return QStringLiteral("%1 page%2").arg(count).arg(count > 1 ? QStringLiteral("s") : QString());
}

void PdfManager::zoomIn() {
    setZoomLevel(qRound((m_zoomLevel + kZoomStep) * 100.0) / 100.0);
}

void PdfManager::zoomOut() {
    setZoomLevel(qRound((m_zoomLevel - kZoomStep) * 100.0) / 100.0);
}

void PdfManager::zoomReset() {
    setZoomLevel(1.0);
}
