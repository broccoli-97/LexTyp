import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import LexTyp

Popup {
    id: citationPicker
    width: 320
    height: 360
    padding: 8
    modal: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    signal citationSelected(string key)

    readonly property color accentColor: "#2979FF"
    readonly property color accentLight: "#E3F2FD"

    ReferenceFilterModel {
        id: pickerFilter
        sourceModel: referenceLibrary
    }

    onOpened: {
        searchInput.text = ""
        searchInput.forceActiveFocus()
    }

    background: Rectangle {
        color: "white"
        radius: 8
        border.color: "#E0E0E0"
        border.width: 1

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 3
            anchors.leftMargin: 3
            anchors.rightMargin: -3
            anchors.bottomMargin: -3
            color: "#18000000"
            radius: 8
            z: -1
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // Header
        Label {
            text: "Insert Citation"
            font.pixelSize: 13
            font.bold: true
            color: "#424242"
            Layout.leftMargin: 4
        }

        // Search field
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 6
            border.color: searchInput.activeFocus ? citationPicker.accentColor : "#E0E0E0"
            border.width: 1
            color: "white"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Label {
                    text: "\uD83D\uDD0D"
                    font.pixelSize: 12
                }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: "Search references\u2026"
                    font.pixelSize: 12
                    background: Item {}
                    padding: 0

                    onTextChanged: pickerFilter.searchQuery = text

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Down) {
                            refList.incrementCurrentIndex()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            refList.decrementCurrentIndex()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (refList.currentIndex >= 0 && refList.count > 0) {
                                var item = refList.itemAtIndex(refList.currentIndex)
                                if (item) {
                                    citationPicker.citationSelected(item.entryKey)
                                    citationPicker.close()
                                }
                            }
                            event.accepted = true
                        }
                    }
                }
            }
        }

        // Reference list
        ListView {
            id: refList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: pickerFilter
            currentIndex: 0

            delegate: Rectangle {
                id: refItem
                required property string key
                required property string entryType
                required property string title
                required property string author
                required property var fields
                required property int index

                property string entryKey: key

                width: refList.width
                height: refCol.implicitHeight + 12
                radius: 6
                color: {
                    if (refList.currentIndex === index) return citationPicker.accentLight
                    if (refMa.containsMouse) return "#F5F5F5"
                    return "transparent"
                }

                Behavior on color { ColorAnimation { duration: 80 } }

                ColumnLayout {
                    id: refCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 6
                    spacing: 2

                    RowLayout {
                        spacing: 6

                        // Type badge
                        Rectangle {
                            Layout.preferredHeight: 16
                            Layout.preferredWidth: badgeLabel.implicitWidth + 10
                            radius: 3
                            color: BibEntryHelper.badgeInfo(entryType).bg

                            Label {
                                id: badgeLabel
                                anchors.centerIn: parent
                                text: BibEntryHelper.badgeInfo(entryType).label
                                font.pixelSize: 9
                                font.bold: true
                                color: BibEntryHelper.badgeInfo(entryType).fg
                            }
                        }

                        // Key
                        Label {
                            text: "@" + key
                            font.pixelSize: 10
                            font.family: "monospace"
                            color: citationPicker.accentColor
                        }
                    }

                    // Title
                    Label {
                        Layout.fillWidth: true
                        text: BibEntryHelper.displayTitle(entryType, fields, key)
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideRight
                        color: "#212121"
                    }

                    // Author
                    Label {
                        Layout.fillWidth: true
                        visible: author.length > 0
                        text: author
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        color: "#757575"
                    }
                }

                MouseArea {
                    id: refMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        citationPicker.citationSelected(key)
                        citationPicker.close()
                    }
                    onEntered: refList.currentIndex = index
                }
            }

            // Empty state
            Label {
                anchors.centerIn: parent
                visible: refList.count === 0
                text: referenceLibrary.entryCount === 0
                      ? "No references loaded.\nLoad a .bib file first."
                      : "No matching references."
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 11
                color: "#9E9E9E"
            }
        }
    }
}
