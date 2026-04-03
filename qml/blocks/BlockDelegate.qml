import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: delegateRoot
    width: ListView.view ? ListView.view.width : 300
    implicitHeight: contentRow.implicitHeight

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

    // Whether this block gets card styling (non-paragraph)
    readonly property bool isCardBlock: nodeType !== 1

    // Placeholder effect: semi-transparent when this block is being dragged
    opacity: {
        var lv = delegateRoot.ListView.view
        return (lv && lv.dragActive && lv.dragSourceIndex === delegateRoot.index) ? 0.3 : 1.0
    }

    HoverHandler {
        id: hoverHandler
        enabled: {
            var lv = delegateRoot.ListView.view
            return !(lv && lv.dragActive)
        }
    }

    RowLayout {
        id: contentRow
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // Left gutter — Notion-style + and drag handle
        Item {
            Layout.preferredWidth: 28
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            opacity: hoverHandler.hovered ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 120 } }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: delegateRoot.isCardBlock ? 8 : 2
                spacing: 0

                // Add block button
                AbstractButton {
                    id: addBtn
                    width: 20; height: 20

                    contentItem: Label {
                        text: "+"
                        font.pixelSize: 16
                        font.weight: Font.Light
                        color: addBtn.hovered ? "#424242" : "#BDBDBD"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 4
                        color: addBtn.hovered ? "#F0F0F0" : "transparent"
                    }
                    onClicked: documentModel.insertNodeBelow(delegateRoot.index, 1)
                    ToolTip.visible: hovered
                    ToolTip.delay: 400
                    ToolTip.text: "Add block below"
                }

                // Drag handle
                Item {
                    width: 20; height: 20

                    Label {
                        anchors.centerIn: parent
                        text: "\u22EE\u22EE"
                        font.pixelSize: 12
                        color: dragHandle.containsMouse ? "#424242" : "#BDBDBD"
                    }

                    MouseArea {
                        id: dragHandle
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.OpenHandCursor

                        onPressed: function(mouse) {
                            mouse.accepted = true
                            var listView = delegateRoot.ListView.view
                            if (listView && listView.startDrag) {
                                var mouseInList = dragHandle.mapToItem(listView, 0, mouseY).y
                                listView.startDrag(delegateRoot.index, mouseInList, contentRow)
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
            }
        }

        // Block content — plain for paragraph, card for others
        Item {
            Layout.fillWidth: true
            Layout.topMargin: 2
            Layout.bottomMargin: 2
            implicitHeight: delegateRoot.isCardBlock ? cardWrapper.height : plainLoader.implicitHeight

            // Plain paragraph (no card)
            Loader {
                id: plainLoader
                visible: !delegateRoot.isCardBlock
                width: parent.width
                sourceComponent: !delegateRoot.isCardBlock ? paragraphComponent : null
                onLoaded: bindProperties()
            }

            // Card wrapper for non-paragraph blocks
            Rectangle {
                id: cardWrapper
                visible: delegateRoot.isCardBlock
                width: parent.width
                height: cardLoader.implicitHeight + 20
                radius: 8

                color: hoverHandler.hovered ? delegateRoot.typeHoverBg : delegateRoot.typeBg
                border.color: hoverHandler.hovered
                    ? Qt.darker(delegateRoot.typeColor, 0.8) : "#E0E0E0"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                // Left accent bar
                Rectangle {
                    width: 4
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 4
                    radius: 2
                    color: delegateRoot.typeColor
                    opacity: hoverHandler.hovered ? 0.8 : 0.4
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Loader {
                    id: cardLoader
                    visible: delegateRoot.isCardBlock
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 16
                    anchors.rightMargin: 12
                    anchors.topMargin: 10

                    sourceComponent: {
                        if (!delegateRoot.isCardBlock) return null
                        switch (delegateRoot.nodeType) {
                        case 0: return titleComponent
                        case 2: return citationComponent
                        case 3: return sectionComponent
                        default: return null
                        }
                    }
                    onLoaded: bindProperties()
                }
            }
        }
    }

    function bindProperties() {
        // Bind to whichever loader is active
        var item = delegateRoot.isCardBlock ? cardLoader.item : plainLoader.item
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
