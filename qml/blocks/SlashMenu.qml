import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: slashMenu
    width: 260
    height: Math.min(menuColumn.implicitHeight + 16, 320)
    padding: 8
    modal: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property string filterText: ""
    property int selectedIndex: 0

    signal itemSelected(int nodeType, int level, bool isInline)

    readonly property var allItems: [
        { icon: "\u00A7",         label: "Section",        nodeType: 0, level: 1, isInline: false, keywords: "section heading h1" },
        { icon: "\u00A7\u00A7",   label: "Subsection",     nodeType: 0, level: 2, isInline: false, keywords: "subsection heading h2" },
        { icon: "\u00A7\u00A7\u00A7", label: "Sub-subsection", nodeType: 0, level: 3, isInline: false, keywords: "sub-subsection heading h3" },
        { icon: "\u00B6",         label: "Paragraph",      nodeType: 1, level: 0, isInline: false, keywords: "paragraph text body" },
        { icon: "\u2295",         label: "Citation",       nodeType: 2, level: 0, isInline: true,  keywords: "citation reference cite oscola footnote" }
    ]

    property var filteredItems: {
        var f = filterText.toLowerCase()
        if (f.length === 0) return allItems
        var result = []
        for (var i = 0; i < allItems.length; i++) {
            var item = allItems[i]
            if (item.label.toLowerCase().indexOf(f) >= 0 ||
                item.keywords.indexOf(f) >= 0) {
                result.push(item)
            }
        }
        return result
    }

    onFilterTextChanged: {
        selectedIndex = 0
    }

    onOpened: {
        selectedIndex = 0
        filterText = ""
    }

    background: Rectangle {
        color: "white"
        radius: 8
        border.color: "#E0E0E0"
        border.width: 1

        // Subtle shadow
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

    function moveUp() {
        if (filteredItems.length > 0)
            selectedIndex = (selectedIndex - 1 + filteredItems.length) % filteredItems.length
    }

    function moveDown() {
        if (filteredItems.length > 0)
            selectedIndex = (selectedIndex + 1) % filteredItems.length
    }

    function selectCurrent() {
        if (filteredItems.length > 0 && selectedIndex < filteredItems.length) {
            var item = filteredItems[selectedIndex]
            itemSelected(item.nodeType, item.level, item.isInline)
        }
        slashMenu.close()
    }

    ColumnLayout {
        id: menuColumn
        anchors.fill: parent
        spacing: 0

        // Filter display
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: "#F5F5F5"
            radius: 4

            Label {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "/" + slashMenu.filterText
                font.pixelSize: 13
                font.family: "monospace"
                color: "#757575"
            }
        }

        Item { Layout.preferredHeight: 4 }

        // Menu items
        Repeater {
            model: slashMenu.filteredItems

            delegate: Rectangle {
                id: menuItem
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 6
                color: {
                    if (index === slashMenu.selectedIndex)
                        return "#E8F0FE"
                    if (itemMa.containsMouse)
                        return "#F5F5F5"
                    return "transparent"
                }

                Behavior on color { ColorAnimation { duration: 80 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    Label {
                        text: modelData.icon
                        font.pixelSize: 15
                        font.bold: true
                        color: "#546E7A"
                        Layout.preferredWidth: 28
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        text: modelData.label
                        font.pixelSize: 13
                        color: index === slashMenu.selectedIndex ? "#1565C0" : "#424242"
                        Layout.fillWidth: true
                    }

                    // Inline indicator for citation
                    Label {
                        visible: modelData.isInline
                        text: "inline"
                        font.pixelSize: 9
                        color: "#9E9E9E"
                    }
                }

                MouseArea {
                    id: itemMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        slashMenu.selectedIndex = index
                        slashMenu.selectCurrent()
                    }
                    onEntered: slashMenu.selectedIndex = index
                }
            }
        }

        // Empty state
        Label {
            visible: slashMenu.filteredItems.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            text: "No matching blocks"
            font.pixelSize: 12
            color: "#BDBDBD"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
