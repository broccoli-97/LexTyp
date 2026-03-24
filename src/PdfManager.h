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

public:
    explicit PdfManager(QObject *parent = nullptr);

    int pageCount() const;
    int version() const;
    QString errorMessage() const;

    Q_INVOKABLE void load(const QString &filePath);
    Q_INVOKABLE QSizeF pageSize(int page) const;

signals:
    void pageCountChanged();
    void versionChanged();
    void errorMessageChanged();
    void documentLoaded();

private:
    QPdfDocument m_document;
    int m_version = 0;
    QString m_errorMessage;
};

#endif // PDFMANAGER_H
