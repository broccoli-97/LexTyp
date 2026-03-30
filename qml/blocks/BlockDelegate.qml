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

    property bool held: false
    property int lastReorderIndex: -1
    property bool reorderCooldown: false

    Timer {
        id: reorderTimer
        interval: 200
        onTriggered: delegateRoot.reorderCooldown = false
    }

    readonly property color typeColor: {
        switch (nodeType) {
        case 0: return "#1565C0"
        case 1: return "#546E7A"
        case 2: return "#E65100"
        case 3: return "#2E7D32"
        default: return "#546E7A"
        }
    }
    readonly property color typeBg: {
        switch (nodeType) {
        case 0: return "#F0F4FA"
        case 1: return "#FAFAFA"
        case 2: return "#FFF8F0"
        case 3: return "#F2F7F2"
        default: return "#FAFAFA"
        }
    }
    readonly property color typeHoverBg: {
        switch (nodeType) {
        case 0: return "#E3ECF7"
        case 1: return "#F0F0F0"
        case 2: return "#FFEFD6"
        case 3: return "#E5EFE5"
        default: return "#F0F0F0"
        }
    }

    Rectangle {
        id: card
        width: delegateRoot.width - 16
        height: cardContent.implicitHeight + 6
        x: 8
        radius: 8

        HoverHandler { id: hoverHandler }

        color: held ? Qt.darker(delegateRoot.typeBg, 1.05)
                    : (hoverHandler.hovered ? delegateRoot.typeHoverBg : delegateRoot.typeBg)

        border.color: cardFocused ? delegateRoot.typeColor
                                  : (hoverHandler.hovered ? Qt.darker(delegateRoot.typeColor, 0.6) : "#E0E0E0")
        border.width: cardFocused ? 2 : 1

        property bool cardFocused: {
            var item = blockLoader.item
            if (!item) return false
            if (item.hasOwnProperty("hasFocus")) return item.hasFocus
            return item.activeFocus
        }

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        // Reparent to ListView during drag — position set only by mouse handler
        states: State {
            when: delegateRoot.held
            ParentChange {
                target: card
                parent: delegateRoot.ListView.view
            }
            PropertyChanges {
                target: card
                z: 100
                opacity: 0.92
            }
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

        // Drop shadow when held
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.leftMargin: 4
            anchors.rightMargin: -4
            anchors.bottomMargin: -4
            color: "#20000000"
            radius: parent.radius
            visible: delegateRoot.held
            z: -1
        }

        // Lift effect
        transform: Scale {
            origin.x: card.width / 2
            origin.y: card.height / 2
            xScale: delegateRoot.held ? 1.02 : 1.0
            yScale: delegateRoot.held ? 1.02 : 1.0
            Behavior on xScale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on yScale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        RowLayout {
            id: cardContent
            anchors.fill: parent
            spacing: 0

            // Drag handle
            Item {
                Layout.preferredWidth: 24
                Layout.fillHeight: true
                opacity: hoverHandler.hovered || delegateRoot.held ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Label {
                    anchors.centerIn: parent
                    text: "\u22EE\u22EE"
                    font.pixelSize: 14
                    color: delegateRoot.held ? delegateRoot.typeColor : "#BDBDBD"
                }

                MouseArea {
                    id: dragHandle
                    anchors.fill: parent
                    cursorShape: Qt.OpenHandCursor

                    onPressed: function(mouse) {
                        mouse.accepted = true
                        delegateRoot.lastReorderIndex = delegateRoot.index
                        delegateRoot.held = true
                        card.x = 8
                        card.y = delegateRoot.mapToItem(delegateRoot.ListView.view, 0, 0).y
                        delegateRoot.ListView.view.interactive = false
                    }

                    onPositionChanged: function(mouse) {
                        if (!delegateRoot.held) return
                        card.y = dragHandle.mapToItem(delegateRoot.ListView.view, 0, mouseY).y - card.height / 2

                        if (delegateRoot.reorderCooldown) return

                        var listView = delegateRoot.ListView.view
                        if (!listView) return

                        var cardCenter = card.y + card.height / 2
                        var itemCount = listView.count
                        var newTargetIndex = -1

                        for (var i = 0; i < itemCount; i++) {
                            var item = listView.itemAtIndex(i)
                            if (item && item !== delegateRoot) {
                                var itemPos = item.mapToItem(listView, 0, 0)
                                var itemCenter = itemPos.y + item.height / 2
                                // Require 60% overlap to prevent borderline oscillation
                                if (Math.abs(cardCenter - itemCenter) < item.height * 0.4) {
                                    newTargetIndex = i
                                    break
                                }
                            }
                        }

                        if (newTargetIndex !== -1 && newTargetIndex !== delegateRoot.lastReorderIndex) {
                            delegateRoot.reorderCooldown = true
                            reorderTimer.restart()
                            documentModel.moveNode(delegateRoot.lastReorderIndex, newTargetIndex)
                            delegateRoot.lastReorderIndex = newTargetIndex
                        }
                    }

                    onReleased: {
                        if (!delegateRoot.held) return
                        delegateRoot.held = false
                        delegateRoot.reorderCooldown = false
                        reorderTimer.stop()
                        var listView = delegateRoot.ListView.view
                        if (listView) listView.interactive = true
                        delegateRoot.lastReorderIndex = -1
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
                opacity: hoverHandler.hovered && !delegateRoot.held ? 1.0 : 0.0
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
