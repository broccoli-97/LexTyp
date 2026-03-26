import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Outer MouseArea — stays in ListView layout, never moves.
// The visual card inside is what gets reparented & dragged.
MouseArea {
    id: dragArea
    width: ListView.view ? ListView.view.width : 300
    implicitHeight: card.height

    required property int index
    required property int nodeType
    required property string content
    required property string nodeId
    required property int level
    required property string prefix
    required property string suffix

    property int currentNodeType: nodeType
    property bool held: false

    // Per-type color palette
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

    // Drag setup — only drag the card, not the delegate
    drag.target: held ? card : undefined
    drag.axis: Drag.YAxis

    hoverEnabled: true

    onPressAndHold: held = true
    onReleased: {
        if (held) {
            held = false
            // Sync visual reorder back to the C++ model
            var vis = DelegateModel.model
            if (vis) {
                // Get the current visual order and determine the move
                var fromModel = dragArea.index
                var toVisual = dragArea.DelegateModel.itemsIndex
                // The visual index IS the target position after all the visual moves
                if (fromModel !== toVisual) {
                    documentModel.moveNode(fromModel, toVisual)
                }
            }
        }
    }

    // Placeholder — shows where the card was while it's being dragged
    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: 8
        color: "#F5F5F5"
        border.color: "#E0E0E0"
        border.width: 1
        visible: held
    }

    // ── The visual card — reparented to ListView root during drag ──
    Rectangle {
        id: card
        width: dragArea.width - 16
        height: cardContent.implicitHeight + 6
        x: 8
        radius: 8

        color: held ? Qt.darker(dragArea.typeBg, 1.05)
                    : (dragArea.containsMouse ? dragArea.typeHoverBg : dragArea.typeBg)

        border.color: cardFocused ? dragArea.typeColor
                                  : (dragArea.containsMouse ? Qt.darker(dragArea.typeColor, 0.6) : "#E0E0E0")
        border.width: cardFocused ? 2 : 1

        property bool cardFocused: {
            var item = blockLoader.item
            if (!item) return false
            if (item.hasOwnProperty("hasFocus")) return item.hasFocus
            return item.activeFocus
        }

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Drag.active: dragArea.held
        Drag.source: dragArea
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        // Reparent to ListView root during drag so it floats above everything
        states: State {
            when: dragArea.held
            ParentChange {
                target: card
                parent: dragArea.ListView.view
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
            color: dragArea.typeColor
            opacity: card.cardFocused ? 1.0 : (dragArea.containsMouse ? 0.5 : 0.2)

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
            visible: dragArea.held
            z: -1
        }

        // Lift effect
        transform: Scale {
            origin.x: card.width / 2
            origin.y: card.height / 2
            xScale: dragArea.held ? 1.02 : 1.0
            yScale: dragArea.held ? 1.02 : 1.0

            Behavior on xScale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on yScale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        // ── Card content ──
        RowLayout {
            id: cardContent
            anchors.fill: parent
            spacing: 0

            // Drag handle
            Item {
                Layout.preferredWidth: 24
                Layout.fillHeight: true
                opacity: dragArea.containsMouse || dragArea.held ? 1.0 : 0.0

                Behavior on opacity { NumberAnimation { duration: 150 } }

                Label {
                    anchors.centerIn: parent
                    text: "\u22EE\u22EE"
                    font.pixelSize: 14
                    color: dragArea.held ? dragArea.typeColor : "#BDBDBD"
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
                        switch (dragArea.nodeType) {
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
                opacity: dragArea.containsMouse && !dragArea.held ? 1.0 : 0.0
                visible: opacity > 0

                Behavior on opacity { NumberAnimation { duration: 150 } }

                ToolButton {
                    width: 24; height: 24
                    text: "+"
                    font.pixelSize: 14
                    onClicked: documentModel.insertNodeBelow(dragArea.index, 1)

                    ToolTip.visible: hovered
                    ToolTip.text: "Add block below"

                    background: Rectangle {
                        radius: 4
                        color: parent.hovered ? "#E3F2FD" : "transparent"
                    }
                }

                ToolButton {
                    width: 24; height: 24
                    text: "\u00D7"
                    font.pixelSize: 14
                    onClicked: documentModel.removeNode(dragArea.index)

                    ToolTip.visible: hovered
                    ToolTip.text: "Delete block"

                    background: Rectangle {
                        radius: 4
                        color: parent.hovered ? "#FFEBEE" : "transparent"
                    }
                }
            }
        }
    }

    // ── Drop area — triggers visual reorder via DelegateModel ──
    DropArea {
        anchors { fill: parent; margins: 8 }
        onEntered: function(drag) {
            var from = drag.source.DelegateModel.itemsIndex
            var to   = dragArea.DelegateModel.itemsIndex
            if (from !== to) {
                var vis = dragArea.DelegateModel.model
                vis.items.move(from, to)
            }
        }
    }

    function bindProperties() {
        var item = blockLoader.item
        if (!item) return

        item.blockIndex = Qt.binding(function() { return dragArea.index })
        item.blockContent = Qt.binding(function() { return dragArea.content })

        if (item.hasOwnProperty("blockLevel"))
            item.blockLevel = Qt.binding(function() { return dragArea.level })
        if (item.hasOwnProperty("blockPrefix"))
            item.blockPrefix = Qt.binding(function() { return dragArea.prefix })
        if (item.hasOwnProperty("blockSuffix"))
            item.blockSuffix = Qt.binding(function() { return dragArea.suffix })
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
