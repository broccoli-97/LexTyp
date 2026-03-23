import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Row {
    id: toolbar
    spacing: 4
    height: 28

    property int blockIndex: -1
    property int currentNodeType: 1

    ComboBox {
        id: typeCombo
        width: 110
        height: parent.height
        model: ["Title", "Paragraph", "Citation"]
        currentIndex: {
            switch (toolbar.currentNodeType) {
            case 0: return 0
            case 1: return 1
            case 2: return 2
            default: return 1
            }
        }
        onActivated: function(index) {
            documentModel.changeNodeType(blockIndex, index)
        }
    }

    Button {
        text: "+"
        width: 28
        height: parent.height
        onClicked: documentModel.insertNodeBelow(blockIndex, 1)
    }

    Button {
        text: "\u2212"
        width: 28
        height: parent.height
        onClicked: documentModel.removeNode(blockIndex)
    }
}
