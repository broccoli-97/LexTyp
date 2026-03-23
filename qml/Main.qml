import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import LexTyp

ApplicationWindow {
    id: root
    width: 1280
    height: 800
    minimumWidth: 900
    minimumHeight: 500
    visible: true
    title: "LexTyp"

    // Theme
    readonly property color accentColor: "#2979FF"
    readonly property color borderColor: "#E0E0E0"

    DocumentModel {
        id: documentModel
    }

    ReferenceLibrary {
        id: referenceLibrary
    }

    Component.onCompleted: {
        documentModel.setReferenceLibrary(referenceLibrary)
    }

    Connections {
        target: documentModel
        function onTypstSourceChanged(source) {
            TypstManager.compile(source)
        }
    }

    Connections {
        target: TypstManager
        function onCompilationFinished(pdfPath) {
            pdfPreview.pdfManager.load(pdfPath)
        }
    }

    Connections {
        target: referenceLibrary
        function onLibraryChanged() {
            // Re-serialize when library changes so footnotes update
            documentModel.setReferenceLibrary(referenceLibrary)
        }
    }

    // Main three-panel layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Main content area: Sidebar | Editor | Preview
        SplitView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: Qt.Horizontal

            // Left sidebar
            SidePanel {
                SplitView.preferredWidth: 220
                SplitView.minimumWidth: 180
                SplitView.maximumWidth: 320
                referenceLibrary: referenceLibrary
            }

            // Center: block editor
            Rectangle {
                SplitView.preferredWidth: root.width * 0.42
                SplitView.minimumWidth: 300
                color: "white"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Editor header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        color: "#FAFAFA"

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: root.borderColor
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 8

                            Label {
                                text: "Document"
                                font.pixelSize: 13
                                font.bold: true
                                color: "#424242"
                            }

                            Item { Layout.fillWidth: true }

                            // Compile status indicator
                            Row {
                                spacing: 6
                                visible: TypstManager.lastPdfPath !== "" || TypstManager.compiling || TypstManager.lastError !== ""

                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: {
                                        if (TypstManager.compiling) return "#FF9800"
                                        if (TypstManager.lastError !== "") return "#F44336"
                                        return "#4CAF50"
                                    }
                                }

                                Label {
                                    text: {
                                        if (TypstManager.compiling) return "Compiling\u2026"
                                        if (TypstManager.lastError !== "") return "Error"
                                        if (TypstManager.lastPdfPath !== "")
                                            return TypstManager.lastDuration + "ms"
                                        return ""
                                    }
                                    font.pixelSize: 11
                                    color: "#757575"
                                }
                            }
                        }
                    }

                    // Block editor
                    BlockListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        Layout.topMargin: 4
                        model: documentModel
                    }
                }
            }

            // Right: PDF preview
            PdfPreview {
                id: pdfPreview
                SplitView.preferredWidth: root.width * 0.35
                SplitView.minimumWidth: 200
            }
        }

        // Status bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            color: "#F5F5F5"

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: root.borderColor
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                Label {
                    font.pixelSize: 11
                    color: "#9E9E9E"
                    text: {
                        if (TypstManager.compiling) return "Compiling\u2026"
                        if (TypstManager.lastError !== "")
                            return "Error: " + TypstManager.lastError
                        if (TypstManager.lastPdfPath !== "")
                            return "Compiled in " + TypstManager.lastDuration + "ms"
                        return "Ready"
                    }
                }

                Item { Layout.fillWidth: true }

                Label {
                    font.pixelSize: 11
                    color: "#BDBDBD"
                    text: documentModel.nodeCount() + " blocks"
                }
            }
        }
    }
}
