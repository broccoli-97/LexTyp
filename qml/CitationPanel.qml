import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import LexTyp

Item {
    id: citationPanel

    // Required from parent
    required property var referenceLibrary
    required property var documentModel

    // Signal emitted when user wants to insert a citation
    signal citationInsertRequested(string key)

    readonly property color accentColor: "#2979FF"
    readonly property color accentLight: "#E3F2FD"
    readonly property color borderColor: "#E0E0E0"

    property string searchQuery: ""
    property var filteredEntries: []

    readonly property var tabModel: ["All", "Cases", "Statutes", "Books", "Academic"]

    function isAcademicType(t) {
        return t !== "case" && t !== "legislation" && t !== "book"
    }

    function badgeInfo(entryType) {
        switch (entryType) {
        case "case":          return { label: "Case",       bg: "#FFF3E0", fg: "#E65100" }
        case "legislation":   return { label: "Statute",    bg: "#E8F5E9", fg: "#2E7D32" }
        case "book":          return { label: "Book",       bg: "#E3F2FD", fg: "#1565C0" }
        case "article":       return { label: "Article",    bg: "#F3E5F5", fg: "#6A1B9A" }
        case "inproceedings": return { label: "Conference", bg: "#FFF8E1", fg: "#F57F17" }
        case "conference":    return { label: "Conference", bg: "#FFF8E1", fg: "#F57F17" }
        case "incollection":  return { label: "Chapter",    bg: "#E0F2F1", fg: "#00695C" }
        case "inbook":        return { label: "Chapter",    bg: "#E0F2F1", fg: "#00695C" }
        case "phdthesis":     return { label: "PhD Thesis", bg: "#FCE4EC", fg: "#880E4F" }
        case "mastersthesis": return { label: "MA Thesis",  bg: "#FCE4EC", fg: "#880E4F" }
        case "techreport":    return { label: "Report",     bg: "#EFEBE9", fg: "#4E342E" }
        case "misc":          return { label: "Misc",       bg: "#ECEFF1", fg: "#37474F" }
        case "online":        return { label: "Online",     bg: "#E8EAF6", fg: "#283593" }
        default:              return { label: entryType,    bg: "#ECEFF1", fg: "#37474F" }
        }
    }

    function secondaryInfo(entryType, f) {
        if (entryType === "case") {
            var parts = []
            if (f.year) parts.push("[" + f.year + "]")
            if (f.court) parts.push(f.court)
            if (f.number) parts.push(f.number)
            return parts.join(" ")
        }
        if (entryType === "legislation") {
            return f.year ? f.year : ""
        }
        if (entryType === "article") {
            var aParts = []
            if (f.author) aParts.push(f.author)
            if (f.journal) aParts.push(f.journal)
            if (f.volume) aParts.push("vol. " + f.volume)
            if (f.year) aParts.push("(" + f.year + ")")
            return aParts.join(", ")
        }
        if (entryType === "inproceedings" || entryType === "conference" ||
            entryType === "incollection" || entryType === "inbook") {
            var cParts = []
            if (f.author) cParts.push(f.author)
            if (f.booktitle) cParts.push("in: " + f.booktitle)
            if (f.year) cParts.push("(" + f.year + ")")
            return cParts.join(", ")
        }
        if (entryType === "phdthesis" || entryType === "mastersthesis") {
            var tParts = []
            if (f.author) tParts.push(f.author)
            if (f.school) tParts.push(f.school)
            if (f.year) tParts.push("(" + f.year + ")")
            return tParts.join(", ")
        }
        // Default: book, techreport, misc, online, etc.
        var defParts = []
        if (f.author) defParts.push(f.author)
        if (f.publisher) defParts.push(f.publisher)
        if (f.year) defParts.push(f.year)
        return defParts.join(", ")
    }

    function refreshEntries() {
        var typeFilter = ""
        var academic = false
        switch (categoryBar.currentIndex) {
        case 0: typeFilter = ""; break
        case 1: typeFilter = "case"; break
        case 2: typeFilter = "legislation"; break
        case 3: typeFilter = "book"; break
        case 4: academic = true; break
        }

        var source
        if (searchQuery.length > 0) {
            source = referenceLibrary.search(searchQuery)
        } else {
            source = referenceLibrary.entries(academic ? "" : typeFilter)
        }

        if (academic) {
            filteredEntries = source.filter(function(e) { return isAcademicType(e.type) })
        } else if (typeFilter.length > 0 && searchQuery.length > 0) {
            filteredEntries = source.filter(function(e) { return e.type === typeFilter })
        } else {
            filteredEntries = source
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

            Repeater {
                model: citationPanel.tabModel
                TabButton {
                    required property string modelData
                    required property int index
                    text: modelData
                    width: implicitWidth
                    font.pixelSize: 11
                    font.bold: categoryBar.currentIndex === index
                    background: Rectangle {
                        color: "transparent"
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 2
                            color: categoryBar.currentIndex === index ? citationPanel.accentColor : "transparent"
                        }
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
                        color: citationPanel.badgeInfo(modelData.type).bg

                        Label {
                            id: typeBadgeText
                            anchors.centerIn: parent
                            text: citationPanel.badgeInfo(modelData.type).label
                            font.pixelSize: 10
                            font.bold: true
                            color: citationPanel.badgeInfo(modelData.type).fg
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
                        text: citationPanel.secondaryInfo(modelData.type, modelData.fields)
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

        // Active citation style label
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.bottomMargin: 8
            radius: 4
            color: citationPanel.accentLight

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8

                Label {
                    text: "Style:"
                    font.pixelSize: 11
                    font.bold: true
                    color: "#616161"
                }

                Label {
                    text: citationPanel.documentModel ? citationPanel.documentModel.citationStyle.toUpperCase() : "OSCOLA"
                    font.pixelSize: 11
                    font.bold: true
                    color: citationPanel.accentColor
                    Layout.fillWidth: true
                }
            }
        }
    }

}
