import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import LexTyp

Item {
    id: citationPanel

    // Required from parent
    required property var referenceLibrary

    // Signal emitted when user wants to insert a citation
    signal citationInsertRequested(string key)

    readonly property color accentColor: "#2979FF"
    readonly property color accentLight: "#E3F2FD"
    readonly property color borderColor: "#E0E0E0"

    property string searchQuery: ""
    property var filteredEntries: []

    function refreshEntries() {
        var typeFilter = ""
        switch (categoryBar.currentIndex) {
        case 0: typeFilter = "case"; break
        case 1: typeFilter = "legislation"; break
        case 2: typeFilter = "book"; break
        }

        if (searchQuery.length > 0) {
            var all = referenceLibrary.search(searchQuery)
            if (typeFilter.length > 0) {
                filteredEntries = all.filter(function(e) { return e.type === typeFilter })
            } else {
                filteredEntries = all
            }
        } else {
            filteredEntries = referenceLibrary.entries(typeFilter)
        }
    }

    Connections {
        target: referenceLibrary
        function onLibraryChanged() { refreshEntries() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Search bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: 8
            radius: 4
            border.color: searchField.activeFocus ? citationPanel.accentColor : citationPanel.borderColor
            border.width: 1
            color: "white"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Label {
                    text: "\uD83D\uDD0D"
                    font.pixelSize: 14
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "Search references\u2026"
                    font.pixelSize: 12
                    background: Item {}

                    onTextChanged: {
                        citationPanel.searchQuery = text
                        refreshEntries()
                    }
                }
            }
        }

        // Category tabs
        TabBar {
            id: categoryBar
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            Layout.topMargin: 4

            background: Rectangle {
                color: "transparent"
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: citationPanel.borderColor
                }
            }

            TabButton {
                text: "Cases"
                width: implicitWidth
                font.pixelSize: 11
                font.bold: categoryBar.currentIndex === 0
                background: Rectangle {
                    color: "transparent"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 2
                        color: categoryBar.currentIndex === 0 ? citationPanel.accentColor : "transparent"
                    }
                }
            }

            TabButton {
                text: "Statutes"
                width: implicitWidth
                font.pixelSize: 11
                font.bold: categoryBar.currentIndex === 1
                background: Rectangle {
                    color: "transparent"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 2
                        color: categoryBar.currentIndex === 1 ? citationPanel.accentColor : "transparent"
                    }
                }
            }

            TabButton {
                text: "Books"
                width: implicitWidth
                font.pixelSize: 11
                font.bold: categoryBar.currentIndex === 2
                background: Rectangle {
                    color: "transparent"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 2
                        color: categoryBar.currentIndex === 2 ? citationPanel.accentColor : "transparent"
                    }
                }
            }

            onCurrentIndexChanged: refreshEntries()
        }

        // Reference cards list
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 8
            clip: true
            spacing: 6
            model: citationPanel.filteredEntries

            delegate: Rectangle {
                required property var modelData
                required property int index

                width: ListView.view ? ListView.view.width : 100
                height: cardContent.implicitHeight + 16
                radius: 6
                color: cardMa.containsMouse ? "#F5F5F5" : "white"
                border.color: cardMa.containsMouse ? citationPanel.accentColor : citationPanel.borderColor
                border.width: 1

                ColumnLayout {
                    id: cardContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    spacing: 3

                    // Reference type badge
                    Rectangle {
                        Layout.preferredHeight: 18
                        Layout.preferredWidth: typeBadgeText.implicitWidth + 12
                        radius: 3
                        color: {
                            var t = modelData.type
                            if (t === "case") return "#FFF3E0"
                            if (t === "legislation") return "#E8F5E9"
                            return "#E3F2FD"
                        }

                        Label {
                            id: typeBadgeText
                            anchors.centerIn: parent
                            text: {
                                var t = modelData.type
                                if (t === "case") return "Case"
                                if (t === "legislation") return "Statute"
                                return "Book"
                            }
                            font.pixelSize: 10
                            font.bold: true
                            color: {
                                var t = modelData.type
                                if (t === "case") return "#E65100"
                                if (t === "legislation") return "#2E7D32"
                                return "#1565C0"
                            }
                        }
                    }

                    // Title / case name
                    Label {
                        Layout.fillWidth: true
                        text: {
                            var f = modelData.fields
                            if (modelData.type === "case")
                                return f.author || f.title || modelData.key
                            return f.title || modelData.key
                        }
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideRight
                        color: "#212121"
                    }

                    // Secondary info
                    Label {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: {
                            var f = modelData.fields
                            if (modelData.type === "case") {
                                var parts = []
                                if (f.year) parts.push("[" + f.year + "]")
                                if (f.court) parts.push(f.court)
                                if (f.number) parts.push(f.number)
                                return parts.join(" ")
                            }
                            if (modelData.type === "legislation") {
                                return f.year ? f.year : ""
                            }
                            // book
                            var bookParts = []
                            if (f.author) bookParts.push(f.author)
                            if (f.publisher) bookParts.push(f.publisher)
                            if (f.year) bookParts.push(f.year)
                            return bookParts.join(", ")
                        }
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        color: "#757575"
                    }

                    // Insert button
                    Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        Layout.topMargin: 4
                        text: "Insert Citation"
                        font.pixelSize: 11

                        background: Rectangle {
                            radius: 4
                            color: parent.hovered ? citationPanel.accentColor : citationPanel.accentLight
                        }
                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: parent.hovered ? "white" : citationPanel.accentColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: citationPanel.citationInsertRequested(modelData.key)
                    }
                }

                MouseArea {
                    id: cardMa
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    acceptedButtons: Qt.NoButton
                }
            }

            // Empty state
            Label {
                anchors.centerIn: parent
                visible: citationPanel.filteredEntries.length === 0
                text: referenceLibrary.entryCount === 0
                      ? "No references loaded.\nLoad a .bib file to get started."
                      : "No matching references."
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 12
                color: "#9E9E9E"
            }
        }

        // Load .bib file button
        Button {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.bottomMargin: 8
            text: "Load .bib File"
            font.pixelSize: 12

            background: Rectangle {
                radius: 4
                color: parent.hovered ? "#F5F5F5" : "white"
                border.color: citationPanel.borderColor
                border.width: 1
            }

            onClicked: bibFileDialog.open()
        }
    }

    FileDialog {
        id: bibFileDialog
        title: "Select BibTeX file"
        nameFilters: ["BibTeX files (*.bib)", "All files (*)"]
        onAccepted: {
            referenceLibrary.loadBibFile(selectedFile)
        }
    }
}
