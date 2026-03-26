import QtQuick
import QtQuick.Controls
import QtQml.Models

ListView {
    id: blockListView
    clip: true
    spacing: 2
    cacheBuffer: 200

    // Source model — set from Main.qml (documentModel)
    property var sourceModel

    model: DelegateModel {
        id: visualModel
        model: blockListView.sourceModel
        delegate: BlockDelegate {}
    }

    // ── Transitions — "soapy water" effect on drop ──

    move: Transition {
        NumberAnimation {
            properties: "x,y"
            duration: 350
            easing.type: Easing.OutBack
            easing.overshoot: 0.6
        }
    }

    displaced: Transition {
        NumberAnimation {
            properties: "x,y"
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    moveDisplaced: Transition {
        NumberAnimation {
            properties: "x,y"
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    add: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0; to: 1.0
                duration: 250
            }
            NumberAnimation {
                property: "y"
                from: -20
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
    }

    remove: Transition {
        SequentialAnimation {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: 200
            }
            NumberAnimation {
                property: "height"
                to: 0
                duration: 150
                easing.type: Easing.InQuad
            }
        }
    }

    addDisplaced: Transition {
        NumberAnimation {
            properties: "x,y"
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    removeDisplaced: Transition {
        NumberAnimation {
            properties: "x,y"
            duration: 300
            easing.type: Easing.OutCubic
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
