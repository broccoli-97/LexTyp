import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: citationBlock
    implicitHeight: citationRow.implicitHeight

    property int blockIndex: -1
    property string blockContent: ""
    property string blockPrefix: ""
    property string blockSuffix: ""

    RowLayout {
        id: citationRow
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // Optional prefix
        TextInput {
            id: prefixInput
            text: blockPrefix
            font.pixelSize: 13
            color: "#424242"
            visible: blockPrefix.length > 0 || prefixInput.activeFocus
            Layout.preferredWidth: visible ? Math.max(implicitWidth + 8, 60) : 0
            selectByMouse: true
            activeFocusOnTab: true

            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                color: prefixInput.activeFocus ? "#F5F5F5" : "transparent"
                radius: 3
                z: -1
            }

            onTextChanged: {
                if (text !== blockPrefix)
                    documentModel.setNodePrefix(blockIndex, text)
            }
        }

        Label {
            visible: prefixInput.visible
            text: " "
            font.pixelSize: 13
        }

        // Citation badge
        Rectangle {
            Layout.preferredHeight: 24
            Layout.preferredWidth: citeBadgeRow.implicitWidth + 16
            radius: 4
            color: "#E3F2FD"
            border.color: "#90CAF9"
            border.width: 1

            Row {
                id: citeBadgeRow
                anchors.centerIn: parent
                spacing: 0

                Label {
                    text: "["
                    font.pixelSize: 13
                    color: "#1565C0"
                }

                TextInput {
                    id: keyInput
                    text: blockContent
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: "#1565C0"
                    selectByMouse: true
                    activeFocusOnTab: true
                    width: Math.max(implicitWidth + 4, 40)

                    onTextChanged: {
                        if (text !== blockContent)
                            documentModel.setNodeContent(blockIndex, text)
                    }
                }

                Label {
                    text: "]"
                    font.pixelSize: 13
                    color: "#1565C0"
                }
            }
        }

        Label {
            visible: suffixInput.visible
            text: " "
            font.pixelSize: 13
        }

        // Optional suffix
        TextInput {
            id: suffixInput
            text: blockSuffix
            font.pixelSize: 13
            color: "#424242"
            visible: blockSuffix.length > 0 || suffixInput.activeFocus
            Layout.preferredWidth: visible ? Math.max(implicitWidth + 8, 60) : 0
            selectByMouse: true
            activeFocusOnTab: true

            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                color: suffixInput.activeFocus ? "#F5F5F5" : "transparent"
                radius: 3
                z: -1
            }

            onTextChanged: {
                if (text !== blockSuffix)
                    documentModel.setNodeSuffix(blockIndex, text)
            }
        }

        Item { Layout.fillWidth: true }
    }
}
