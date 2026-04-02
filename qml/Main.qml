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

    // Raw editor state
    property bool rawEditMode: false
    property string capturedSource: ""

    onRawEditModeChanged: {
        if (rawEditMode)
            rawEditor.text = capturedSource
        // switching back: blocks are unchanged — no re-parse needed
    }

    DocumentModel {
        id: documentModel
    }

    ReferenceLibrary {
        id: referenceLibrary
    }

    // ── File dialogs ──────────────────────────────────────────────────────────

    // Open .lextyp project
    FileDialog {
        id: openProjectDialog
        title: "Open Project"
        nameFilters: ["LexTyp project (*.lextyp)", "All files (*)"]
        onAccepted: documentModel.loadProject(selectedFile)
    }

    // Import .typ file into editor
    FileDialog {
        id: importTypstDialog
        title: "Import Typst File"
        nameFilters: ["Typst file (*.typ)", "All files (*)"]
        onAccepted: documentModel.loadTypst(selectedFile)
    }

    // Load bibliography
    FileDialog {
        id: openBibDialog
        title: "Open Bibliography"
        nameFilters: ["BibTeX files (*.bib)", "All files (*)"]
        onAccepted: referenceLibrary.loadBibFile(selectedFile.toString())
    }

    // Save .lextyp project
    FileDialog {
        id: saveProjectDialog
        title: "Save Project"
        fileMode: FileDialog.SaveFile
        acceptLabel: "Save"
        nameFilters: ["LexTyp project (*.lextyp)"]
        defaultSuffix: "lextyp"
        currentFolder: documentModel.defaultProjectFolderUrl
        currentFile: documentModel.defaultProjectSaveUrl
        onAccepted: documentModel.saveProject(selectedFile)
    }

    // Export .typ file
    FileDialog {
        id: exportTypstDialog
        title: "Export as Typst"
        fileMode: FileDialog.SaveFile
        acceptLabel: "Export"
        nameFilters: ["Typst file (*.typ)"]
        defaultSuffix: "typ"
        onAccepted: documentModel.exportTypst(selectedFile)
    }

    // ── Compile info popup ────────────────────────────────────────────────────
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
                    text: TypstManager.compilationDetail
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
            capturedSource = source
            TypstManager.compile(source)
        }
        function onRequestSaveAs() {
            saveProjectDialog.open()
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
            documentModel.setReferenceLibrary(referenceLibrary)
        }
    }


    // ── Main layout ───────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0


        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // The NavigationBar is now placed in a fixed-width container matching its collapsed state.
            // When it expands, its visual width increases by floating over (z: 10).
            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: 48 // Matches Nav bar's collapsed width, so main content doesn't shift
                z: 10

                NavigationBar {
                    id: navigationBar
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left

                    // Added mouse area to detect enter/exit for auto-expand/collapse
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true

                        onEntered: navigationBar.expanded = true
                        onExited: navigationBar.expanded = false

                        // We need this to pass clicks down to the buttons
                        onClicked: (mouse) => mouse.accepted = false
                        onPressed: (mouse) => mouse.accepted = false
                        onReleased: (mouse) => mouse.accepted = false
                    }

                    onOutlineClicked: {
                        sidePanel.currentIndex = 0
                        sidePanel.visible = true
                    }
                    onReferencesClicked: {
                        sidePanel.currentIndex = 1
                        sidePanel.visible = true
                    }
                    onNewProjectClicked: {
                        documentModel.newProject()
                    }
                    onOpenClicked: {
                        openProjectDialog.open()
                    }
                    onImportTypstClicked: {
                        importTypstDialog.open()
                    }
                    onSaveClicked: {
                        documentModel.saveProject()
                    }
                    onExportTypstClicked: {
                        exportTypstDialog.open()
                    }
                    onLoadBibClicked: {
                        openBibDialog.open()
                    }
                    onSettingsClicked: {
                        console.log("Settings clicked")
                    }
                }
            }

            SplitView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Horizontal

                // ── Left sidebar ──────────────────────────────────────────────────
                SidePanel {
                    id: sidePanel
                    SplitView.preferredWidth: 220
                    SplitView.minimumWidth: 180
                    SplitView.maximumWidth: 320
                    referenceLibrary: referenceLibrary
                    docModel: documentModel
                }

                // ── Center: editor panel ──────────────────────────────────────────
                Rectangle {
                    SplitView.preferredWidth: root.width * 0.42
                    SplitView.minimumWidth: 300
                    color: "white"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // ── Header bar ────────────────────────────────────────────
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
                                anchors.rightMargin: 8
                                spacing: 6

                                Label {
                                    text: "Document"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    color: "#333333"
                                }

                                Item { Layout.fillWidth: true }

                                // ── View toggle: Blocks / Text ────────────────────
                                Row {
                                    spacing: 0

                                    AbstractButton {
                                        id: blocksToggle
                                        height: 28
                                        implicitWidth: contentRow.implicitWidth + 16

                                        contentItem: Row {
                                            id: contentRow
                                            spacing: 4
                                            leftPadding: 8
                                            rightPadding: 8
                                            Label {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "\u229E"   // ⊞
                                                font.pixelSize: 12
                                                color: !rawEditMode ? root.accentColor : "#757575"
                                            }
                                            Label {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Blocks"
                                                font.pixelSize: 12
                                                color: !rawEditMode ? root.accentColor : "#757575"
                                            }
                                        }
                                        background: Rectangle {
                                            radius: 4
                                            color: !rawEditMode ? "#E8F0FE" : (blocksToggle.hovered ? "#F0F0F0" : "transparent")
                                            border.color: !rawEditMode ? root.accentColor : root.borderColor
                                            border.width: 1
                                        }
                                        onClicked: rawEditMode = false
                                        ToolTip.visible: hovered
                                        ToolTip.text: "Block editor"
                                    }

                                    Item { width: 4 }

                                    AbstractButton {
                                        id: textToggle
                                        height: 28
                                        implicitWidth: textToggleRow.implicitWidth + 16

                                        contentItem: Row {
                                            id: textToggleRow
                                            spacing: 4
                                            leftPadding: 8
                                            rightPadding: 8
                                            Label {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "{ }"
                                                font.pixelSize: 11
                                                font.family: "monospace"
                                                color: rawEditMode ? root.accentColor : "#757575"
                                            }
                                            Label {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Typst"
                                                font.pixelSize: 12
                                                color: rawEditMode ? root.accentColor : "#757575"
                                            }
                                        }
                                        background: Rectangle {
                                            radius: 4
                                            color: rawEditMode ? "#E8F0FE" : (textToggle.hovered ? "#F0F0F0" : "transparent")
                                            border.color: rawEditMode ? root.accentColor : root.borderColor
                                            border.width: 1
                                        }
                                        onClicked: rawEditMode = true
                                        ToolTip.visible: hovered
                                        ToolTip.text: "View generated Typst source (read-only)"
                                    }
                                }

                                Item { width: 4 }
                            }
                        }

                        // ── Block toolbar (block mode only) ───────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: visible ? 32 : 0
                            visible: !rawEditMode
                            color: "#F5F5F5"

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 1
                                color: root.borderColor
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 2

                                Repeater {
                                    model: [
                                        { label: "Title",     type: 0, icon: "T" },
                                        { label: "Section",   type: 3, icon: "§" },
                                        { label: "Paragraph", type: 1, icon: "¶" }
                                    ]

                                    delegate: AbstractButton {
                                        id: toolBtn
                                        height: 24
                                        anchors.verticalCenter: parent.verticalCenter

                                        contentItem: Row {
                                            spacing: 4
                                            leftPadding: 8
                                            rightPadding: 8
                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 14; height: 14; radius: 3
                                                color: toolBtn.hovered ? root.accentColor : "#E0E0E0"
                                                Label {
                                                    anchors.centerIn: parent
                                                    text: modelData.icon
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: toolBtn.hovered ? "white" : "#757575"
                                                }
                                            }
                                            Label {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: modelData.label
                                                font.pixelSize: 11
                                                color: toolBtn.hovered ? "#333333" : "#616161"
                                            }
                                        }
                                        background: Rectangle {
                                            radius: 12
                                            color: toolBtn.hovered ? "#EBEBEB" : "transparent"
                                        }
                                        onClicked: documentModel.insertNode(documentModel.nodeCount(), modelData.type)
                                        ToolTip.visible: hovered
                                        ToolTip.delay: 500
                                        ToolTip.text: "Add " + modelData.label.toLowerCase() + " block at end"
                                    }
                                }
                            }
                        }

                        // ── Content area: block editor OR raw text ────────────────
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            // Block editor
                            BlockListView {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                anchors.topMargin: 4
                                sourceModel: documentModel
                                visible: !rawEditMode
                            }

                            // Raw Typst editor
                            Rectangle {
                                anchors.fill: parent
                                visible: rawEditMode
                                color: "#1E1E1E"

                                ScrollView {
                                    anchors.fill: parent
                                    clip: true

                                    TextArea {
                                        id: rawEditor
                                        readOnly: true
                                        wrapMode: TextArea.Wrap
                                        font.family: "monospace"
                                        font.pixelSize: 12
                                        color: "#D4D4D4"
                                        selectionColor: root.accentColor
                                        selectedTextColor: "white"
                                        leftPadding: 16
                                        topPadding: 12
                                        background: null
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Right: PDF preview ────────────────────────────────────────────
                PdfPreview {
                    id: pdfPreview
                    SplitView.preferredWidth: root.width * 0.35
                    SplitView.minimumWidth: 200
                }
            }
        }

        // ── Status bar ────────────────────────────────────────────────────────
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
                            text: TypstManager.statusText
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
                    text: rawEditMode ? "Raw Typst" : documentModel.nodeCount() + " blocks"
                }
            }
        }
    }
}
