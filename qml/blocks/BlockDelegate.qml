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
    property bool isFocused: blockLoader.item ? blockLoader.item.activeFocus : false

    // Drag state
    property bool held: false

    // Left accent bar + content
    RowLayout {
        id: contentRow
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // Left accent indicator
        Rectangle {
            Layout.preferredWidth: 3
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            radius: 1.5
            color: {
                if (isFocused) return "#2979FF"
                if (isHovered) return "#BBDEFB"
                return "transparent"
            }

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }

        // Drag handle (visible on hover)
        Item {
            Layout.preferredWidth: 20
            Layout.fillHeight: true
            opacity: isHovered || held ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            Label {
                anchors.centerIn: parent
                text: "\u2630"
                font.pixelSize: 11
                color: "#BDBDBD"
            }

            MouseArea {
                id: handleMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.OpenHandCursor
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
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            Layout.rightMargin: 4
            implicitHeight: blockLoader.implicitHeight

            Loader {
                id: blockLoader
                width: parent.width
                sourceComponent: {
                    switch (delegate.nodeType) {
                    case 0: return titleComponent
                    case 1: return paragraphComponent
                    case 2: return citationComponent
                    default: return paragraphComponent
                    }
                }
                onLoaded: bindProperties()
            }
        }

        // Hover toolbar (minimal)
        Row {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 6
            spacing: 2
            opacity: isHovered ? 1.0 : 0.0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            ToolButton {
                width: 22
                height: 22
                text: "+"
                font.pixelSize: 14
                onClicked: documentModel.insertNodeBelow(delegate.index, 1)

                ToolTip.visible: hovered
                ToolTip.text: "Add block below"

                background: Rectangle {
                    radius: 3
                    color: parent.hovered ? "#F5F5F5" : "transparent"
                }
            }

            ToolButton {
                width: 22
                height: 22
                text: "\u00D7"
                font.pixelSize: 14
                onClicked: documentModel.removeNode(delegate.index)

                ToolTip.visible: hovered
                ToolTip.text: "Delete block"

                background: Rectangle {
                    radius: 3
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
}
