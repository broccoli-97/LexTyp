import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: delegate
    width: ListView.view ? ListView.view.width : 300
    implicitHeight: contentRow.implicitHeight

    required property int index
    required property int nodeType
    required property string content
    required property string nodeId
    required property int level
    required property string prefix
    required property string suffix

    property int currentNodeType: nodeType
    property bool isHovered: delegateMouseArea.containsMouse
    property bool isFocused: {
        var item = blockLoader.item
        if (!item) return false
        // ParagraphBlock is an Item wrapper; use its hasFocus property
        if (item.hasOwnProperty("hasFocus")) return item.hasFocus
        return item.activeFocus
    }

    // Drag state
    property bool held: false

    // Card Background
    Rectangle {
        id: card
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        
        radius: 8
        color: held ? "#EEEEEE" : (isHovered ? "#F5F5F5" : "#FFFFFF")
        
        // Permanent border to make cards distinct
        border.color: isFocused ? "#2979FF" : (isHovered ? "#BDBDBD" : "#E0E0E0")
        border.width: isFocused ? 2 : 1

        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }

        // Left accent bar (visible when focused)
        Rectangle {
            width: 4
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 4
            radius: 2
            visible: isFocused
            color: "#2979FF"
        }

        // Drag shadow
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 6
            anchors.leftMargin: 6
            anchors.rightMargin: -6
            anchors.bottomMargin: -6
            color: "#1A000000"
            radius: parent.radius
            visible: held
            z: -1
        }
    }

    // Layout
    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 0

        // Drag handle
        Item {
            Layout.preferredWidth: 24
            Layout.fillHeight: true
            opacity: isHovered || held ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            Label {
                anchors.centerIn: parent
                text: "\u22EE\u22EE" // Vertical dots
                font.pixelSize: 14
                color: held ? "#2979FF" : "#BDBDBD"
            }

            MouseArea {
                id: handleMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SizeAllCursor
                drag.target: delegate
                drag.axis: Drag.YAxis

                onPressed: {
                    delegate.held = true
                    delegate.z = 100
                }
                onReleased: {
                    delegate.held = false
                    delegate.z = 0
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
                    switch (delegate.nodeType) {
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
            opacity: isHovered && !held ? 1.0 : 0.0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            ToolButton {
                width: 24
                height: 24
                text: "+"
                font.pixelSize: 14
                onClicked: documentModel.insertNodeBelow(delegate.index, 1)

                ToolTip.visible: hovered
                ToolTip.text: "Add block below"

                background: Rectangle {
                    radius: 4
                    color: parent.hovered ? "#E3F2FD" : "transparent"
                }
            }

            ToolButton {
                width: 24
                height: 24
                text: "\u00D7"
                font.pixelSize: 14
                onClicked: documentModel.removeNode(delegate.index)

                ToolTip.visible: hovered
                ToolTip.text: "Delete block"

                background: Rectangle {
                    radius: 4
                    color: parent.hovered ? "#FFEBEE" : "transparent"
                }
            }
        }
    }

    function bindProperties() {
        var item = blockLoader.item
        if (!item) return

        item.blockIndex = Qt.binding(function() { return delegate.index })
        item.blockContent = Qt.binding(function() { return delegate.content })

        if (item.hasOwnProperty("blockLevel"))
            item.blockLevel = Qt.binding(function() { return delegate.level })
        if (item.hasOwnProperty("blockPrefix"))
            item.blockPrefix = Qt.binding(function() { return delegate.prefix })
        if (item.hasOwnProperty("blockSuffix"))
            item.blockSuffix = Qt.binding(function() { return delegate.suffix })
    }

    // Drop area for reordering
    DropArea {
        anchors.fill: parent
        onEntered: function(drag) {
            var fromItem = drag.source
            if (fromItem && fromItem !== delegate && fromItem.index !== undefined) {
                documentModel.moveNode(fromItem.index, delegate.index)
            }
        }
    }

    Drag.active: held
    Drag.source: delegate
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    MouseArea {
        id: delegateMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
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
