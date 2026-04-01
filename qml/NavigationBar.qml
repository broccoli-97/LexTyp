import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: navBar
    width: expanded ? 200 : 48
    color: "#F3F3F3"

    property bool expanded: false

    Behavior on width {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuint }
    }

    // Theme colors
    readonly property color accentColor: "#2979FF"
    readonly property color hoverColor: "#EBEBEB"
    readonly property color pressedColor: "#D6D6D6"
    readonly property color iconColor: "#1A1A1A"

    // Signals for actions
    signal toggleMenu()
    signal openClicked()
    signal saveClicked()
    signal settingsClicked()
    signal outlineClicked()
    signal referencesClicked()

    property int currentIndex: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top section
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            spacing: 4
            anchors.margins: 4

            // Menu toggle
            NavButton {
                iconText: "\u2261" // Hamburger menu icon
                label: "Menu"
                showLabel: navBar.expanded
                toolTip: "Toggle Menu"
                onClicked: navBar.expanded = !navBar.expanded
            }

            Item { Layout.preferredHeight: 8 } // Spacer

            // Outline
            NavButton {
                iconText: "\uD83D\uDCDC" // Scroll (outline)
                label: "Outline"
                showLabel: navBar.expanded
                toolTip: "Document Outline"
                active: navBar.currentIndex === 0
                onClicked: {
                    navBar.currentIndex = 0
                    navBar.outlineClicked()
                }
            }

            // References
            NavButton {
                iconText: "\uD83D\uDCDA" // Books (references)
                label: "References"
                showLabel: navBar.expanded
                toolTip: "Reference Library"
                active: navBar.currentIndex === 1
                onClicked: {
                    navBar.currentIndex = 1
                    navBar.referencesClicked()
                }
            }

            Item { Layout.preferredHeight: 8 } // Spacer

            // Open project / file
            NavButton {
                iconText: "\uD83D\uDCC2" // Folder icon
                label: "Open"
                showLabel: navBar.expanded
                toolTip: "Open Project (.zip) or File (.typ)"
                onClicked: navBar.openClicked()
            }

            // Save project
            NavButton {
                iconText: "\uD83D\uDCBE" // Floppy disk icon
                label: "Save"
                showLabel: navBar.expanded
                toolTip: "Save Project (.zip)"
                onClicked: navBar.saveClicked()
            }
        }

        Item { Layout.fillHeight: true } // Flexible spacer

        // Bottom section
        ColumnLayout {
            Layout.alignment: Qt.AlignBottom
            Layout.fillWidth: true
            spacing: 4
            anchors.margins: 4
            anchors.bottomMargin: 8

            // Settings
            NavButton {
                iconText: "\u2699" // Gear icon
                label: "Settings"
                showLabel: navBar.expanded
                toolTip: "Settings"
                active: navBar.currentIndex === 2
                onClicked: {
                    // navBar.currentIndex = 2 // maybe we don't want to switch tab for settings?
                    navBar.settingsClicked()
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
        color: "#E0E0E0"
    }

    // Custom button component matching WinUI style
    component NavButton: AbstractButton {
        id: btn
        property string iconText: ""
        property string label: ""
        property bool showLabel: false
        property string toolTip: ""
        property bool active: false

        Layout.fillWidth: true
        Layout.preferredHeight: 36
        Layout.alignment: Qt.AlignHCenter
        Layout.leftMargin: 4
        Layout.rightMargin: 4

        contentItem: Row {
            spacing: 12
            leftPadding: 10

            Text {
                text: btn.iconText
                font.pixelSize: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: navBar.iconColor
                width: 20
            }

            Text {
                text: btn.label
                visible: btn.showLabel
                font.pixelSize: 13
                color: navBar.iconColor
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
                opacity: btn.showLabel ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        background: Rectangle {
            radius: 4
            color: {
                if (btn.pressed) return navBar.pressedColor
                if (btn.hovered || btn.active) return navBar.hoverColor
                return "transparent"
            }

            // Left accent bar like WinUI when active
            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: 18
                width: 3
                radius: 1.5
                color: navBar.accentColor
                visible: btn.active
            }
        }

        ToolTip.visible: hovered && !showLabel
        ToolTip.text: btn.toolTip
        ToolTip.delay: 500
    }
}
