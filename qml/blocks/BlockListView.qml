import QtQuick
import QtQuick.Controls

ListView {
    id: blockListView
    clip: true
    spacing: 0

    delegate: BlockDelegate {}

    // Animation for moving items
    move: Transition {
        NumberAnimation {
            properties: "y"
            duration: 250
            easing.type: Easing.InOutQuad
        }
    }

    // Animation for other items making room
    displaced: Transition {
        NumberAnimation {
            properties: "y"
            duration: 250
            easing.type: Easing.InOutQuad
        }
    }

    // Animation for newly added items
    add: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1.0
            duration: 200
        }
    }

    // Animation for removed items
    remove: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: 200
            }
            NumberAnimation {
                property: "height"
                to: 0
                duration: 200
            }
        }
    }

    moveDisplaced: Transition {
        NumberAnimation {
            properties: "y"
            duration: 250
            easing.type: Easing.InOutQuad
        }
    }

    // Placeholder when empty
    Column {
        anchors.centerIn: parent
        spacing: 8
        visible: blockListView.count === 0

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No blocks yet"
            font.pixelSize: 14
            color: "#BDBDBD"
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Use the sidebar to add a title or paragraph"
            font.pixelSize: 12
            color: "#BDBDBD"
        }
    }
}
