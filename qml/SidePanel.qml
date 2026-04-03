import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import LexTyp

Item {
    id: sidePanel

    // Required from parent
    required property var referenceLibrary
    required property var docModel

    // Theme colors (accessible by children)
    readonly property color accentColor: "#2979FF"
    readonly property color accentLight: "#E3F2FD"
    readonly property color borderColor: "#E0E0E0"
    readonly property color bgColor: "#FAFAFA"

    Rectangle {
        anchors.fill: parent
        color: bgColor
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "transparent"

            Label {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "References"
                font.pixelSize: 16
                font.weight: Font.DemiBold
                color: "#1A1A1A"
            }
        }

        // References content
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            CitationPanel {
                anchors.fill: parent
                referenceLibrary: sidePanel.referenceLibrary
                documentModel: sidePanel.docModel

                onCitationInsertRequested: function(key) {
                    sidePanel.docModel.insertCitation(key)
                }
            }
        }
    }

    // Right border
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: borderColor
    }
}
