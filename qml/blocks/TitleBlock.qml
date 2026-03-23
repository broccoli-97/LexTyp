import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: titleBlock
    implicitHeight: titleInput.implicitHeight + 4

    property int blockIndex: -1
    property int blockLevel: 1
    property string blockContent: ""

    TextInput {
        id: titleInput
        anchors.left: parent.left
        anchors.right: parent.right
        text: blockContent
        font.pixelSize: {
            switch (blockLevel) {
            case 1: return 22
            case 2: return 19
            case 3: return 16
            default: return 14
            }
        }
        font.weight: Font.DemiBold
        color: "#212121"
        wrapMode: TextInput.Wrap
        selectByMouse: true
        activeFocusOnTab: true

        onTextChanged: {
            if (text !== blockContent)
                documentModel.setNodeContent(blockIndex, text)
        }
    }
}
