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

    property alias currentIndex: tabBar.currentIndex

    Rectangle {
        anchors.fill: parent
        color: bgColor
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Tab bar (now optionally visible or used internally)
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 36 : 0
            visible: false // Hidden by default since we use NavigationBar

            background: Rectangle {
                color: sidePanel.bgColor
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: sidePanel.borderColor
                }
            }

            TabButton {
                text: "Outline"
                width: implicitWidth
                font.pixelSize: 12
                font.bold: tabBar.currentIndex === 0

                background: Rectangle {
                    color: "transparent"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 2
                        color: tabBar.currentIndex === 0 ? sidePanel.accentColor : "transparent"
                    }
                }
            }

            TabButton {
                text: "References"
                width: implicitWidth
                font.pixelSize: 12
                font.bold: tabBar.currentIndex === 1

                background: Rectangle {
                    color: "transparent"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 2
                        color: tabBar.currentIndex === 1 ? sidePanel.accentColor : "transparent"
                    }
                }
            }
        }

        // Content area
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "transparent"
            visible: true

            Label {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: tabBar.currentIndex === 0 ? "Outline" : "References"
                font.pixelSize: 16
                font.weight: Font.DemiBold
                color: "#1A1A1A"
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            // Outline tab
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    // Outline list of blocks
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 1
                        model: documentModel

                        delegate: Rectangle {
                            required property int index
                            required property int nodeType
                            required property string content
                            required property int level
                            required property int outlineIndent
                            required property string outlineText

                            width: ListView.view ? ListView.view.width : 100
                            height: 44
                            radius: 4
                            color: outlineMa.containsMouse ? "#F5F5F5" : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: outlineIndent
                                anchors.rightMargin: 8
                                spacing: 6

                                Rectangle {
                                    width: 3
                                    height: 24
                                    radius: 1.5
                                    color: {
                                        switch (nodeType) {
                                        case 0: return sidePanel.accentColor
                                        case 1: return "#90A4AE"
                                        case 2: return "#FF9800"
                                        default: return "#90A4AE"
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Label {
                                        Layout.fillWidth: true
                                        text: outlineText
                                        font.pixelSize: nodeType === 0 ? 12 : 11
                                        font.bold: nodeType === 0
                                        elide: Text.ElideRight
                                        color: "#424242"
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        visible: nodeType === 0
                                        text: "Heading " + level
                                        font.pixelSize: 10
                                        color: "#9E9E9E"
                                    }
                                }
                            }

                            MouseArea {
                                id: outlineMa
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }
            }

            // References tab — Citation Panel
            Item {
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
