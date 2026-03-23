import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import LexTyp

Item {
    id: pdfPreview

    property alias pdfManager: pdfMgr

    readonly property color previewBg: "#3C3C3C"
    readonly property color headerBg: "#2C2C2C"

    PdfManager {
        id: pdfMgr
    }

    Rectangle {
        anchors.fill: parent
        color: previewBg
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: headerBg

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                Label {
                    text: "Live Preview"
                    font.bold: true
                    font.pixelSize: 13
                    color: "#E0E0E0"
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: pdfMgr.pageCount > 0
                          ? pdfMgr.pageCount + " page" + (pdfMgr.pageCount > 1 ? "s" : "")
                          : ""
                    font.pixelSize: 11
                    color: "#9E9E9E"
                }
            }
        }

        // Page area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: flickable
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: pageColumn.height + 32

                Column {
                    id: pageColumn
                    width: flickable.width
                    spacing: 16
                    topPadding: 16

                    Repeater {
                        model: pdfMgr.pageCount

                        // Page with drop shadow
                        Item {
                            width: pageColumn.width - 48
                            anchors.horizontalCenter: parent.horizontalCenter

                            property var pgSize: pdfMgr.pageSize(index)
                            property real aspect: pgSize.height > 0 ? pgSize.width / pgSize.height : 0.707

                            height: aspect > 0 ? width / aspect : width * 1.414

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

                            // Page number
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
            }

            // Compiling overlay
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

            // Empty state
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
                    text: pdfMgr.errorMessage !== "" ? pdfMgr.errorMessage : "Edit blocks to generate a preview"
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
