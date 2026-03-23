import QtQuick
import QtQuick.Controls

ListView {
    id: blockListView
    clip: true
    spacing: 0

    delegate: BlockDelegate {}

    moveDisplaced: Transition {
        NumberAnimation {
            properties: "y"
            duration: 200
            easing.type: Easing.OutQuad
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
