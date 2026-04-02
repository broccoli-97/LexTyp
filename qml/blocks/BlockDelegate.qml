import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: delegateRoot
    width: ListView.view ? ListView.view.width : 300
    implicitHeight: card.height

    required property int index
    required property int nodeType
    required property string content
    required property string nodeId
    required property int level
    required property string prefix
    required property string suffix

    required property string typeColor
    required property string typeBg
    required property string typeHoverBg

    // Placeholder effect: semi-transparent when this block is being dragged
    opacity: {
        var lv = delegateRoot.ListView.view
        return (lv && lv.dragActive && lv.dragSourceIndex === delegateRoot.index) ? 0.3 : 1.0
    }

    Rectangle {
        id: card
        width: delegateRoot.width - 16
        height: cardContent.implicitHeight + 6
        x: 8
        radius: 8

        HoverHandler {
            id: hoverHandler
            // Suppress hover effects during drag to avoid visual noise
            enabled: {
                var lv = delegateRoot.ListView.view
                return !(lv && lv.dragActive)
            }
        }

        color: hoverHandler.hovered ? delegateRoot.typeHoverBg : delegateRoot.typeBg

        border.color: cardFocused ? delegateRoot.typeColor
                                  : (hoverHandler.hovered ? Qt.darker(delegateRoot.typeColor, 0.6) : "#E0E0E0")
        border.width: cardFocused ? 2 : 1

        property bool cardFocused: {
            var item = blockLoader.item
            if (!item) return false
            if (item.hasOwnProperty("hasFocus")) return item.hasFocus
            return item.activeFocus
        }

        Behavior on color {
            enabled: {
                var lv = delegateRoot.ListView.view
                return !(lv && lv.dragActive)
            }
            ColorAnimation { duration: 120 }
        }
        Behavior on border.color {
            enabled: {
                var lv = delegateRoot.ListView.view
                return !(lv && lv.dragActive)
            }
            ColorAnimation { duration: 120 }
        }

        // Left accent bar
        Rectangle {
            width: 4
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 4
            radius: 2
            color: delegateRoot.typeColor
            opacity: card.cardFocused ? 1.0 : (hoverHandler.hovered ? 0.5 : 0.2)
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        RowLayout {
            id: cardContent
            anchors.fill: parent
            spacing: 0

            // Drag handle
            Item {
                Layout.preferredWidth: 24
                Layout.fillHeight: true
                opacity: hoverHandler.hovered ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Label {
                    anchors.centerIn: parent
                    text: "\u22EE\u22EE"
                    font.pixelSize: 14
                    color: "#BDBDBD"
                }

                MouseArea {
                    id: dragHandle
                    anchors.fill: parent
                    cursorShape: Qt.OpenHandCursor

                    onPressed: function(mouse) {
                        mouse.accepted = true
                        var listView = delegateRoot.ListView.view
                        if (listView && listView.startDrag) {
                            var mouseInList = dragHandle.mapToItem(listView, 0, mouseY).y
                            listView.startDrag(delegateRoot.index, mouseInList, card)
                        }
                    }

                    onPositionChanged: function(mouse) {
                        var listView = delegateRoot.ListView.view
                        if (listView && listView.dragActive) {
                            var mouseInList = dragHandle.mapToItem(listView, 0, mouseY).y
                            listView.updateDrag(mouseInList)
                        }
                    }

                    onReleased: {
                        var listView = delegateRoot.ListView.view
                        if (listView && listView.endDrag) {
                            listView.endDrag()
                        }
                    }
                }
            }

            // Block content
            Item {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                Layout.leftMargin: 4
                Layout.rightMargin: 8
                implicitHeight: blockLoader.implicitHeight

                Loader {
                    id: blockLoader
                    width: parent.width
                    sourceComponent: {
                        switch (delegateRoot.nodeType) {
                        case 0: return titleComponent
                        case 1: return paragraphComponent
                        case 2: return citationComponent
                        case 3: return sectionComponent
                        default: return paragraphComponent
                        }
                    }
                    onLoaded: bindProperties()
                }
            }

            // Hover toolbar
            Row {
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 8
                spacing: 2
                opacity: hoverHandler.hovered ? 1.0 : 0.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                ToolButton {
                    width: 24; height: 24
                    text: "\u2191"
                    font.pixelSize: 14
                    visible: delegateRoot.index > 0
                    onClicked: documentModel.moveNode(delegateRoot.index, delegateRoot.index - 1)
                    ToolTip.visible: hovered
                    ToolTip.text: "Move block up"
                    background: Rectangle { radius: 4; color: parent.hovered ? "#E8EAF6" : "transparent" }
                }

                ToolButton {
                    width: 24; height: 24
                    text: "\u2193"
                    font.pixelSize: 14
                    visible: delegateRoot.index < documentModel.nodeCount() - 1
                    onClicked: documentModel.moveNode(delegateRoot.index, delegateRoot.index + 1)
                    ToolTip.visible: hovered
                    ToolTip.text: "Move block down"
                    background: Rectangle { radius: 4; color: parent.hovered ? "#E8EAF6" : "transparent" }
                }

                ToolButton {
                    width: 24; height: 24
                    text: "+"
                    font.pixelSize: 14
                    onClicked: documentModel.insertNodeBelow(delegateRoot.index, 1)
                    ToolTip.visible: hovered
                    ToolTip.text: "Add block below"
                    background: Rectangle { radius: 4; color: parent.hovered ? "#E3F2FD" : "transparent" }
                }

                ToolButton {
                    width: 24; height: 24
                    text: "\u00D7"
                    font.pixelSize: 14
                    onClicked: documentModel.removeNode(delegateRoot.index)
                    ToolTip.visible: hovered
                    ToolTip.text: "Delete block"
                    background: Rectangle { radius: 4; color: parent.hovered ? "#FFEBEE" : "transparent" }
                }
            }
        }
    }

    function bindProperties() {
        var item = blockLoader.item
        if (!item) return
        item.blockIndex = Qt.binding(function() { return delegateRoot.index })
        item.blockContent = Qt.binding(function() { return delegateRoot.content })
        if (item.hasOwnProperty("blockLevel"))
            item.blockLevel = Qt.binding(function() { return delegateRoot.level })
        if (item.hasOwnProperty("blockPrefix"))
            item.blockPrefix = Qt.binding(function() { return delegateRoot.prefix })
        if (item.hasOwnProperty("blockSuffix"))
            item.blockSuffix = Qt.binding(function() { return delegateRoot.suffix })
    }

    Component {
        id: titleComponent
        TitleBlock {}
    }

    Component {
        id: paragraphComponent
        ParagraphBlock {}
    }

    Component {
        id: citationComponent
        CitationBlock {}
    }

    Component {
        id: sectionComponent
        SectionBlock {}
    }
}
