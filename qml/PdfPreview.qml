import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import LexTyp

Item {
    id: pdfPreview

    property alias pdfManager: pdfMgr

    readonly property color previewBg: "#3C3C3C"
    readonly property color headerBg: "#2C2C2C"

    PdfManager {
        id: pdfMgr
    }

    FileDialog {
        id: savePdfDialog
        title: "Save PDF"
        fileMode: FileDialog.SaveFile
        nameFilters: ["PDF files (*.pdf)"]
        defaultSuffix: "pdf"
        currentFolder: documentModel.defaultProjectFolderUrl
        currentFile: "file://" + documentModel.documentsPath + "/document.pdf"
        onAccepted: Qt.copyFile(TypstManager.lastPdfPath, savePdfDialog.selectedFile)
    }

    Rectangle {
        anchors.fill: parent
        color: previewBg
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ────────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: headerBg

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 4

                Label {
                    text: "Live Preview"
                    font.bold: true
                    font.pixelSize: 13
                    color: "#E0E0E0"
                }

                Item { Layout.fillWidth: true }

                // ── Zoom controls ────────────────────────────────────────────
                Row {
                    spacing: 0

                    // Zoom out
                    ToolButton {
                        id: zoomOutBtn
                        width: 26; height: 26
                        enabled: pdfMgr.pageCount > 0 && pdfMgr.zoomLevel > 0.25
                        onClicked: pdfMgr.zoomOut()
                        ToolTip.visible: hovered
                        ToolTip.text: "Zoom out"
                        contentItem: Text {
                            text: "\u2212"   // − minus sign
                            font.pixelSize: 16
                            font.weight: Font.Medium
                            color: zoomOutBtn.enabled ? "#D0D0D0" : "#606060"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 4
                            color: zoomOutBtn.hovered && zoomOutBtn.enabled ? "#484848" : "transparent"
                        }
                    }

                    // Percentage label — click resets to 100%
                    Rectangle {
                        width: 46; height: 26
                        radius: 4
                        color: percentHover.containsMouse ? "#484848" : "transparent"

                        Label {
                            anchors.centerIn: parent
                            text: Math.round(pdfMgr.zoomLevel * 100) + "%"
                            font.pixelSize: 11
                            color: pdfMgr.pageCount > 0 ? "#C8C8C8" : "#606060"
                        }

                        HoverHandler { id: percentHover }
                        TapHandler {
                            enabled: pdfMgr.pageCount > 0
                            onTapped: pdfMgr.zoomReset()
                        }
                        ToolTip.visible: percentHover.hovered
                        ToolTip.text: "Reset zoom to 100%"
                    }

                    // Zoom in
                    ToolButton {
                        id: zoomInBtn
                        width: 26; height: 26
                        enabled: pdfMgr.pageCount > 0 && pdfMgr.zoomLevel < 3.0
                        onClicked: pdfMgr.zoomIn()
                        ToolTip.visible: hovered
                        ToolTip.text: "Zoom in"
                        contentItem: Text {
                            text: "+"
                            font.pixelSize: 16
                            font.weight: Font.Medium
                            color: zoomInBtn.enabled ? "#D0D0D0" : "#606060"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 4
                            color: zoomInBtn.hovered && zoomInBtn.enabled ? "#484848" : "transparent"
                        }
                    }
                }

                // ── Page count ───────────────────────────────────────────────
                Label {
                    text: pdfMgr.pageCountText
                    font.pixelSize: 11
                    color: "#9E9E9E"
                    leftPadding: 4
                }

                // ── Download / save button ────────────────────────────────────
                ToolButton {
                    id: saveBtn
                    width: 30; height: 30
                    enabled: pdfMgr.pageCount > 0 && TypstManager.lastPdfPath !== ""
                    onClicked: savePdfDialog.open()
                    ToolTip.visible: hovered
                    ToolTip.text: "Save PDF\u2026"
                    contentItem: Text {
                        text: "\u2B07"   // ⬇ downward arrow
                        font.pixelSize: 15
                        color: saveBtn.enabled ? "#D0D0D0" : "#606060"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 4
                        color: saveBtn.hovered && saveBtn.enabled ? "#484848" : "transparent"
                    }
                }
            }
        }

        // ── Page area ─────────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: flickable
                anchors.fill: parent
                clip: true

                // When zoomed beyond 100% the content is wider than the viewport
                contentWidth: Math.max(width,
                                       pdfMgr.zoomLevel * (width - 48) + 48)
                contentHeight: pageColumn.height + 32

                Column {
                    id: pageColumn
                    // Column stretches to at least the viewport, wider on zoom-in
                    width: Math.max(flickable.width,
                                    pdfMgr.zoomLevel * (flickable.width - 48) + 48)
                    spacing: 16
                    topPadding: 16

                    Repeater {
                        model: pdfMgr.pageCount

                        // Page with drop shadow
                        Item {
                            // Explicit scaled width; centred inside the column
                            width: pdfMgr.zoomLevel * (flickable.width - 48)
                            anchors.horizontalCenter: parent.horizontalCenter

                            property var pgSize: pdfMgr.pageSize(index)
                            property real aspect: pgSize.height > 0 ? pgSize.width / pgSize.height : 0.707

                            height: aspect > 0 ? width / aspect : width * 1.414

                            Behavior on width  { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            // Shadow
                            Rectangle {
                                anchors.fill: pageRect
                                anchors.topMargin: 2
                                anchors.leftMargin: 2
                                anchors.rightMargin: -2
                                anchors.bottomMargin: -2
                                color: "#40000000"
                                radius: 1
                            }

                            // Page
                            Rectangle {
                                id: pageRect
                                anchors.fill: parent
                                color: "white"
                                radius: 1

                                Image {
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: false
                                    sourceSize.width: width * 2
                                    source: "image://pdf/" + index + "?v=" + pdfMgr.version
                                }
                            }

                            // Page number badge
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottomMargin: -20
                                width: pageLabel.implicitWidth + 12
                                height: 18
                                radius: 9
                                color: "#50000000"

                                Label {
                                    id: pageLabel
                                    anchors.centerIn: parent
                                    text: (index + 1) + " / " + pdfMgr.pageCount
                                    font.pixelSize: 10
                                    color: "#E0E0E0"
                                }
                            }
                        }
                    }

                    // Bottom padding
                    Item { width: 1; height: 16 }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
                ScrollBar.horizontal: ScrollBar {
                    policy: pdfMgr.zoomLevel > 1.0 ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }
            }

            // ── Compiling overlay ─────────────────────────────────────────────
            Rectangle {
                anchors.fill: parent
                visible: TypstManager.compiling
                color: "#60000000"
                z: 10

                Column {
                    anchors.centerIn: parent
                    spacing: 12

                    BusyIndicator {
                        anchors.horizontalCenter: parent.horizontalCenter
                        running: TypstManager.compiling
                        palette.dark: "#E0E0E0"
                    }

                    Label {
                        text: "Compiling\u2026"
                        color: "#E0E0E0"
                        font.pixelSize: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // ── Empty state ───────────────────────────────────────────────────
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: pdfMgr.pageCount === 0 && !TypstManager.compiling

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\uD83D\uDCC4"
                    font.pixelSize: 32
                    color: "#757575"
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: pdfMgr.errorMessage !== ""
                          ? pdfMgr.errorMessage
                          : "Edit blocks to generate a preview"
                    color: "#757575"
                    font.pixelSize: 12
                }
            }
        }
    }

    // Left border separator
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: "#505050"
    }
}
