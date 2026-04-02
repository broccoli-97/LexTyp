#ifndef PDFMANAGER_H
#define PDFMANAGER_H

#include <QObject>
#include <QPdfDocument>
#include <QQmlEngine>
#include <QQuickImageProvider>

class PdfPageImageProvider : public QQuickImageProvider
{
public:
    explicit PdfPageImageProvider();

    QImage requestImage(const QString &id, QSize *size,
                        const QSize &requestedSize) override;

    void setDocument(QPdfDocument *doc);

    static PdfPageImageProvider *globalInstance();
    static void setGlobalInstance(PdfPageImageProvider *provider);

private:
    QPdfDocument *m_doc = nullptr;
    static PdfPageImageProvider *s_instance;
};

class PdfManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int pageCount READ pageCount NOTIFY pageCountChanged)
    Q_PROPERTY(int version READ version NOTIFY versionChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(qreal zoomLevel READ zoomLevel WRITE setZoomLevel NOTIFY zoomLevelChanged)
    Q_PROPERTY(QString pageCountText READ pageCountText NOTIFY pageCountChanged)

public:
    explicit PdfManager(QObject *parent = nullptr);

    int pageCount() const;
    int version() const;
    QString errorMessage() const;
    qreal zoomLevel() const { return m_zoomLevel; }
    void setZoomLevel(qreal level);
    QString pageCountText() const;

    Q_INVOKABLE void load(const QString &filePath);
    Q_INVOKABLE QSizeF pageSize(int page) const;
    Q_INVOKABLE void zoomIn();
    Q_INVOKABLE void zoomOut();
    Q_INVOKABLE void zoomReset();

signals:
    void pageCountChanged();
    void versionChanged();
    void errorMessageChanged();
    void zoomLevelChanged();
    void documentLoaded();

private:
    QPdfDocument m_document;
    int m_version = 0;
    QString m_errorMessage;
    qreal m_zoomLevel = 1.0;

    static constexpr qreal kZoomMin = 0.25;
    static constexpr qreal kZoomMax = 3.0;
    static constexpr qreal kZoomStep = 0.25;
};

#endif // PDFMANAGER_H
