import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: sectionBlock
    implicitHeight: sectionInput.implicitHeight + 12

    property int blockIndex: -1
    property string blockContent: ""

    TextInput {
        id: sectionInput
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 6
        text: blockContent
        font.pixelSize: 14
        font.weight: Font.Bold
        font.capitalization: Font.AllUppercase
        color: "#757575"
        wrapMode: TextInput.Wrap
        selectByMouse: true
        activeFocusOnTab: true

        onTextChanged: {
            if (text !== blockContent)
                documentModel.setNodeContent(blockIndex, text)
        }
    }
}
