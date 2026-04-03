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

                    onReferencesClicked: {
                        sidePanel.visible = !sidePanel.visible
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
                    id: editorPanel
                    SplitView.preferredWidth: root.width * 0.42
                    SplitView.minimumWidth: 300
                    color: "white"

                    // ── Content area: block editor OR raw text ────────────────
                    Item {
                        anchors.fill: parent

                        // Block editor
                        BlockListView {
                            id: blockListView
                            anchors.fill: parent
                            anchors.leftMargin: 24
                            anchors.rightMargin: 24
                            anchors.topMargin: 16
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

                        // ── Floating outline (Notion-style) ──────────────────
                        Rectangle {
                            id: floatingOutline
                            visible: !rawEditMode && hasOutlineItems
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.rightMargin: 8
                            anchors.topMargin: 16
                            width: 160
                            height: Math.min(outlineCol.implicitHeight + 24, parent.height * 0.6)
                            radius: 8
                            color: "#F8F8F8"
                            opacity: outlineHover.hovered ? 0.95 : 0.6
                            border.color: "#E8E8E8"
                            border.width: 1
                            z: 50

                            property bool hasOutlineItems: false

                            Behavior on opacity { NumberAnimation { duration: 200 } }

                            HoverHandler { id: outlineHover }

                            Flickable {
                                anchors.fill: parent
                                anchors.margins: 12
                                contentHeight: outlineCol.implicitHeight
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                Column {
                                    id: outlineCol
                                    width: parent.width
                                    spacing: 2

                                    Label {
                                        text: "Outline"
                                        font.pixelSize: 10
                                        font.bold: true
                                        font.capitalization: Font.AllUppercase
                                        color: "#9E9E9E"
                                        bottomPadding: 4
                                    }

                                    Repeater {
                                        id: outlineRepeater
                                        model: documentModel

                                        delegate: Item {
                                            id: outlineItem
                                            required property int index
                                            required property int nodeType
                                            required property string content
                                            required property int level
                                            width: outlineCol.width
                                            height: visible ? outlineLabel.implicitHeight + 4 : 0
                                            visible: nodeType === 0

                                            Component.onCompleted: updateHasOutline()
                                            Component.onDestruction: updateHasOutline()
                                            onVisibleChanged: updateHasOutline()

                                            function updateHasOutline() {
                                                var found = false
                                                for (var i = 0; i < outlineRepeater.count; i++) {
                                                    var item = outlineRepeater.itemAt(i)
                                                    if (item && item.visible) { found = true; break }
                                                }
                                                floatingOutline.hasOutlineItems = found
                                            }

                                            Label {
                                                id: outlineLabel
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.leftMargin: level > 1 ? (level - 1) * 10 : 0
                                                text: content.length > 0 ? content : "Untitled"
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                                color: outlineItemMa.containsMouse ? "#1565C0" : "#616161"
                                            }

                                            MouseArea {
                                                id: outlineItemMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    blockListView.positionViewAtIndex(outlineItem.index, ListView.Beginning)
                                                }
                                            }
                                        }
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
