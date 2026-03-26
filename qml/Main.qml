import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
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

    // Active paragraph tracking for inline citation insertion
    property int activeParagraphIndex: -1
    property int activeCursorPosition: -1

    DocumentModel {
        id: documentModel
    }

    ReferenceLibrary {
        id: referenceLibrary
    }

    FileDialog {
        id: openTypstDialog
        title: "Open Typst File"
        nameFilters: ["Typst files (*.typ)", "All files (*)"]
        onAccepted: documentModel.loadTypst(selectedFile)
    }

    // Compile Info Popup — anchored above the footer status button
    Popup {
        id: compileInfoPopup
        x: 12
        y: root.height - height - 34
        width: 420
        height: Math.min(400, compileInfoScroll.contentHeight + 48)
        padding: 12
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "white"
            radius: 8
            border.color: root.borderColor
            border.width: 1
            
            // Stable shadow
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 4
                anchors.leftMargin: 4
                anchors.rightMargin: -4
                anchors.bottomMargin: -4
                color: "#15000000"
                radius: 8
                z: -1
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Label {
                text: "Compilation Details"
                font.bold: true
                font.pixelSize: 14
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.borderColor
            }

            ScrollView {
                id: compileInfoScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                TextArea {
                    text: {
                        var msg = "Status: " + (TypstManager.compiling ? "Compiling..." : (TypstManager.lastError ? "Error" : "Success")) + "\n"
                        if (TypstManager.lastDuration > 0)
                            msg += "Duration: " + (TypstManager.lastDuration / 1000.0).toFixed(2) + "s\n"
                        if (TypstManager.lastError)
                            msg += "\nError Message:\n" + TypstManager.lastError
                        return msg
                    }
                    readOnly: true
                    wrapMode: TextArea.Wrap
                    font.family: "monospace"
                    font.pixelSize: 11
                    color: TypstManager.lastError ? "#D32F2F" : "#424242"
                    background: null
                    padding: 0
                }
            }
        }
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
                docModel: documentModel
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
                        Layout.preferredHeight: 44
                        color: "#FAFAFA"

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: root.borderColor
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 6

                            Label {
                                text: "Document"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: "#333333"
                            }

                            Item { Layout.preferredWidth: 4 }

                            // Insert block buttons — compact pill style
                            Repeater {
                                model: [
                                    { label: "Title", type: 0, icon: "T" },
                                    { label: "Section", type: 3, icon: "S" },
                                    { label: "Paragraph", type: 1, icon: "P" }
                                ]

                                delegate: AbstractButton {
                                    id: addBtn
                                    Layout.preferredHeight: 28
                                    padding: 0

                                    contentItem: Row {
                                        spacing: 4
                                        leftPadding: 8
                                        rightPadding: 10

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 16; height: 16; radius: 3
                                            color: addBtn.hovered ? root.accentColor : "#E0E0E0"

                                            Label {
                                                anchors.centerIn: parent
                                                text: "+"
                                                font.pixelSize: 11
                                                font.weight: Font.Bold
                                                color: addBtn.hovered ? "white" : "#757575"
                                            }
                                        }

                                        Label {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.label
                                            font.pixelSize: 12
                                            color: addBtn.hovered ? "#333333" : "#616161"
                                        }
                                    }

                                    background: Rectangle {
                                        radius: 14
                                        color: addBtn.hovered ? "#F0F0F0" : "transparent"
                                        border.color: addBtn.hovered ? "#D0D0D0" : "transparent"
                                    }

                                    onClicked: documentModel.insertNode(documentModel.nodeCount(), modelData.type)

                                    ToolTip.visible: hovered
                                    ToolTip.delay: 600
                                    ToolTip.text: "Add " + modelData.label.toLowerCase() + " block"
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Open file button
                            AbstractButton {
                                id: openBtn
                                Layout.preferredHeight: 28
                                padding: 0

                                contentItem: Row {
                                    spacing: 5
                                    leftPadding: 10
                                    rightPadding: 10

                                    Label {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "\u{1F4C2}"
                                        font.pixelSize: 13
                                    }
                                    Label {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Open"
                                        font.pixelSize: 12
                                        color: openBtn.hovered ? "#333333" : "#757575"
                                    }
                                }

                                background: Rectangle {
                                    radius: 14
                                    color: openBtn.hovered ? "#F0F0F0" : "transparent"
                                    border.color: openBtn.hovered ? "#D0D0D0" : "transparent"
                                }

                                onClicked: openTypstDialog.open()
                                ToolTip.visible: hovered
                                ToolTip.delay: 600
                                ToolTip.text: "Open a Typst file"
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
                        sourceModel: documentModel
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
            Layout.preferredHeight: 26
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
                spacing: 8

                // Compile status indicator — clickable to open popup
                AbstractButton {
                    id: compileStatusBtn
                    Layout.preferredHeight: 22
                    padding: 0

                    contentItem: Row {
                        spacing: 6
                        leftPadding: 6
                        rightPadding: 8

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8; height: 8; radius: 4
                            color: {
                                if (TypstManager.compiling) return "#2196F3"
                                if (TypstManager.lastError !== "") return "#F44336"
                                return "#4CAF50"
                            }

                            SequentialAnimation on scale {
                                running: TypstManager.compiling
                                loops: Animation.Infinite
                                NumberAnimation { to: 1.4; duration: 500; easing.type: Easing.InOutQuad }
                                NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
                            }
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 11
                            color: compileStatusBtn.hovered ? "#424242" : "#9E9E9E"
                            text: {
                                if (TypstManager.compiling) return "Compiling\u2026"
                                if (TypstManager.lastError !== "") return "Error"
                                if (TypstManager.lastPdfPath !== "")
                                    return "Compiled in " + TypstManager.lastDuration + "ms"
                                return "Ready"
                            }
                        }
                    }

                    background: Rectangle {
                        radius: 4
                        color: compileStatusBtn.hovered ? "#EEEEEE" : "transparent"
                    }

                    onClicked: compileInfoPopup.opened ? compileInfoPopup.close() : compileInfoPopup.open()
                    ToolTip.visible: hovered
                    ToolTip.delay: 400
                    ToolTip.text: "Click to view compilation details"
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
