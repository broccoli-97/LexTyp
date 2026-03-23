import QtQuick
import QtQuick.Controls

TextArea {
    id: paragraphArea

    property int blockIndex: -1
    property string blockContent: ""

    text: blockContent
    placeholderText: "Type something\u2026"
    font.pixelSize: 14
    color: "#424242"
    wrapMode: TextEdit.Wrap
    background: null
    padding: 0
    topPadding: 2
    bottomPadding: 2
    activeFocusOnTab: true

    placeholderTextColor: "#BDBDBD"

    onTextChanged: {
        if (text !== blockContent)
            documentModel.setNodeContent(blockIndex, text)
    }
}
