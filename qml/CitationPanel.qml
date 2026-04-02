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

    property var selectedEntry: null

    readonly property var tabModel: ["All", "Cases", "Statutes", "Books", "Academic"]

    ReferenceFilterModel {
        id: filterModel
        sourceModel: citationPanel.referenceLibrary
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ─── Detail View ───
        Item {
            id: detailView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: citationPanel.selectedEntry !== null

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Back button + type badge header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    Layout.topMargin: 8
                    spacing: 8

                    Button {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        flat: true
                        text: "\u2190"
                        font.pixelSize: 16

                        background: Rectangle {
                            radius: 4
                            color: parent.hovered ? "#F5F5F5" : "transparent"
                        }

                        onClicked: citationPanel.selectedEntry = null
                    }

                    Rectangle {
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: detailBadgeText.implicitWidth + 14
                        radius: 4
                        color: citationPanel.selectedEntry ? BibEntryHelper.badgeInfo(citationPanel.selectedEntry.type).bg : "transparent"

                        Label {
                            id: detailBadgeText
                            anchors.centerIn: parent
                            text: citationPanel.selectedEntry ? BibEntryHelper.badgeInfo(citationPanel.selectedEntry.type).label : ""
                            font.pixelSize: 11
                            font.bold: true
                            color: citationPanel.selectedEntry ? BibEntryHelper.badgeInfo(citationPanel.selectedEntry.type).fg : "#000"
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // Citation key
                Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    Layout.topMargin: 8
                    text: citationPanel.selectedEntry ? "@" + citationPanel.selectedEntry.key : ""
                    font.pixelSize: 11
                    font.family: "monospace"
                    color: citationPanel.accentColor
                }

                // Title
                Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    Layout.topMargin: 4
                    text: citationPanel.selectedEntry
                          ? BibEntryHelper.displayTitle(citationPanel.selectedEntry.type,
                                                        citationPanel.selectedEntry.fields,
                                                        citationPanel.selectedEntry.key)
                          : ""
                    font.pixelSize: 14
                    font.bold: true
                    wrapMode: Text.Wrap
                    color: "#212121"
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    Layout.topMargin: 10
                    Layout.bottomMargin: 6
                    color: citationPanel.borderColor
                }

                // Fields list
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 12
                    Layout.rightMargin: 12
                    contentHeight: fieldsColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: fieldsColumn
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: {
                                if (!citationPanel.selectedEntry) return []
                                var f = citationPanel.selectedEntry.fields
                                var keys = Object.keys(f)
                                var result = []
                                for (var i = 0; i < keys.length; i++) {
                                    if (f[keys[i]] && f[keys[i]].length > 0)
                                        result.push({ fieldKey: keys[i], fieldValue: f[keys[i]] })
                                }
                                return result
                            }

                            ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 1

                                Label {
                                    text: BibEntryHelper.fieldLabel(modelData.fieldKey)
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: "#757575"
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.fieldValue
                                    font.pixelSize: 12
                                    wrapMode: Text.Wrap
                                    color: "#424242"
                                }
                            }
                        }
                    }
                }

                // Insert button
                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    Layout.margins: 12
                    text: "Insert Citation"
                    font.pixelSize: 12

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

                    onClicked: {
                        if (citationPanel.selectedEntry)
                            citationPanel.citationInsertRequested(citationPanel.selectedEntry.key)
                    }
                }
            }
        }

        // ─── List View ───

        // Search bar
        Rectangle {
            visible: citationPanel.selectedEntry === null
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
                        filterModel.searchQuery = text
                    }
                }
            }
        }

        // Category tabs
        TabBar {
            id: categoryBar
            visible: citationPanel.selectedEntry === null
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

            onCurrentIndexChanged: filterModel.categoryIndex = currentIndex
        }

        // Reference cards list
        ListView {
            visible: citationPanel.selectedEntry === null
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 8
            clip: true
            spacing: 6
            model: filterModel

            delegate: Rectangle {
                required property string key
                required property string entryType
                required property string title
                required property string author
                required property var fields
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
                        color: BibEntryHelper.badgeInfo(entryType).bg

                        Label {
                            id: typeBadgeText
                            anchors.centerIn: parent
                            text: BibEntryHelper.badgeInfo(entryType).label
                            font.pixelSize: 10
                            font.bold: true
                            color: BibEntryHelper.badgeInfo(entryType).fg
                        }
                    }

                    // Title / case name
                    Label {
                        Layout.fillWidth: true
                        text: BibEntryHelper.displayTitle(entryType, fields, key)
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideRight
                        color: "#212121"
                    }

                    // Secondary info
                    Label {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: BibEntryHelper.secondaryInfo(entryType, fields)
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

                        onClicked: citationPanel.citationInsertRequested(key)
                    }
                }

                MouseArea {
                    id: cardMa
                    anchors.fill: parent
                    z: -1
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        citationPanel.selectedEntry = referenceLibrary.entryByKey(key)
                    }
                }
            }

            // Empty state
            Label {
                anchors.centerIn: parent
                visible: filterModel.count === 0
                text: referenceLibrary.entryCount === 0
                      ? "No references loaded.\nLoad a .bib file to get started."
                      : "No matching references."
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 12
                color: "#9E9E9E"
            }
        }

        // Citation style selector
        Rectangle {
            visible: citationPanel.selectedEntry === null
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.bottomMargin: 8
            radius: 4
            color: citationPanel.accentLight

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Label {
                    text: "Style:"
                    font.pixelSize: 11
                    font.bold: true
                    color: "#616161"
                }

                ComboBox {
                    id: styleCombo
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    font.pixelSize: 11
                    model: citationPanel.documentModel ? citationPanel.documentModel.availableStyles() : []
                    currentIndex: {
                        if (!citationPanel.documentModel) return 0
                        var styles = citationPanel.documentModel.availableStyles()
                        var current = citationPanel.documentModel.citationStyle
                        for (var i = 0; i < styles.length; i++) {
                            if (styles[i] === current) return i
                        }
                        return 0
                    }

                    displayText: currentText.toUpperCase()

                    delegate: ItemDelegate {
                        required property string modelData
                        required property int index
                        width: styleCombo.width
                        height: 28
                        contentItem: Text {
                            text: modelData.toUpperCase()
                            font.pixelSize: 11
                            font.bold: styleCombo.currentIndex === index
                            color: styleCombo.currentIndex === index ? citationPanel.accentColor : "#424242"
                            verticalAlignment: Text.AlignVCenter
                        }
                        highlighted: styleCombo.highlightedIndex === index
                        background: Rectangle {
                            color: highlighted ? citationPanel.accentLight : "transparent"
                        }
                    }

                    background: Rectangle {
                        radius: 4
                        color: styleCombo.hovered ? "#D6E4FF" : "transparent"
                        border.color: styleCombo.pressed ? citationPanel.accentColor : "transparent"
                        border.width: 1
                    }

                    contentItem: Text {
                        text: styleCombo.displayText
                        font.pixelSize: 11
                        font.bold: true
                        color: citationPanel.accentColor
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 4
                    }

                    onActivated: function(index) {
                        if (citationPanel.documentModel) {
                            var styles = citationPanel.documentModel.availableStyles()
                            citationPanel.documentModel.setCitationStyle(styles[index])
                        }
                    }

                    Connections {
                        target: citationPanel.documentModel
                        function onCitationStyleChanged() {
                            var styles = citationPanel.documentModel.availableStyles()
                            var current = citationPanel.documentModel.citationStyle
                            for (var i = 0; i < styles.length; i++) {
                                if (styles[i] === current) {
                                    styleCombo.currentIndex = i
                                    return
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}
