import QtQuick
import QtQuick.Controls
import LexTyp

Item {
    id: paragraphRoot

    property int blockIndex: -1
    property string blockContent: ""

    // Sync tracking to break binding loop
    property string lastModelContent: ""
    property bool updatingFromModel: false

    // Deferred overlay data
    property var citationRanges: []

    // Cursor snapping guard
    property int snappingGuard: 0

    implicitHeight: paragraphArea.implicitHeight

    TextArea {
        id: paragraphArea
        anchors.fill: parent

        placeholderText: "Type something\u2026"
        font.pixelSize: 14
        color: "#424242"
        wrapMode: TextEdit.Wrap
        textFormat: TextEdit.PlainText
        background: null
        padding: 0
        topPadding: 2
        bottomPadding: 2
        activeFocusOnTab: true

        placeholderTextColor: "#BDBDBD"

        onTextChanged: {
            if (!paragraphRoot.updatingFromModel) {
                paragraphRoot.lastModelContent = text
                documentModel.setNodeContent(blockIndex, text)
            }
            overlayTimer.restart()
        }

        onActiveFocusChanged: {
            if (activeFocus) {
                documentModel.activeParagraphIndex = blockIndex
                documentModel.activeCursorPosition = cursorPosition
            }
        }

        onCursorPositionChanged: {
            if (activeFocus) {
                var cit = CitationRangeHelper.citationAt(paragraphRoot.citationRanges, cursorPosition)
                if (Object.keys(cit).length > 0 && paragraphRoot.snappingGuard < 2) {
                    paragraphRoot.snappingGuard++
                    var distToStart = cursorPosition - cit.start
                    var distToEnd = cit.snapEnd - cursorPosition
                    if (distToStart <= distToEnd) {
                        paragraphArea.cursorPosition = cit.start
                    } else {
                        paragraphArea.cursorPosition = cit.snapEnd
                    }
                    snapGuardReset.restart()
                    return
                }
                documentModel.activeCursorPosition = cursorPosition
            }
        }

        onWidthChanged: overlayTimer.restart()
        onContentSizeChanged: overlayTimer.restart()

        Keys.onPressed: function(event) {
            var pos = paragraphArea.cursorPosition

            // Check character input blocking
            if (event.text.length > 0) {
                var charResult = CitationRangeHelper.handleKeyAction(
                    paragraphRoot.citationRanges, pos, -1, event.text)
                if (charResult.action === "block") {
                    event.accepted = true
                    return
                }
            }

            // Check specific key actions
            var result = CitationRangeHelper.handleKeyAction(
                paragraphRoot.citationRanges, pos, event.key, "")
            if (result.action === "block") {
                event.accepted = true
            } else if (result.action === "move") {
                paragraphArea.cursorPosition = result.cursorPos
                event.accepted = true
            } else if (result.action === "delete") {
                paragraphArea.remove(result.deleteStart, result.deleteEnd)
                event.accepted = true
            }
        }

        Component.onCompleted: {
            paragraphArea.text = blockContent
            paragraphRoot.lastModelContent = blockContent
        }
    }

    // React to external model changes (e.g. insertInlineCitation)
    onBlockContentChanged: {
        if (blockContent !== lastModelContent) {
            updatingFromModel = true
            var savedPos = paragraphArea.cursorPosition
            var oldLen = lastModelContent.length
            paragraphArea.text = blockContent
            lastModelContent = blockContent
            // Advance cursor past inserted text (e.g. after insertInlineCitation)
            var newLen = blockContent.length
            var newPos = savedPos + (newLen - oldLen)
            if (newPos > paragraphArea.length) newPos = paragraphArea.length
            if (newPos < 0) newPos = 0
            paragraphArea.cursorPosition = newPos
            updatingFromModel = false
        }
        overlayTimer.restart()
    }

    // Deferred overlay computation — fires after layout pass
    Timer {
        id: overlayTimer
        interval: 50
        onTriggered: {
            var textRanges = CitationRangeHelper.parseCiteKeys(paragraphArea.text)
            var result = []
            for (var i = 0; i < textRanges.length; i++) {
                var r = textRanges[i]
                var startPos = r.start
                var endPos = r.end
                if (endPos > paragraphArea.length) continue
                var r1 = paragraphArea.positionToRectangle(startPos)
                var r2 = paragraphArea.positionToRectangle(endPos)
                // Only overlay if the match is on a single line
                if (Math.abs(r1.y - r2.y) < 2) {
                    var w = Math.max(r2.x - r1.x, 30)
                    r.rect = Qt.rect(r1.x, r1.y, w, r1.height)
                    result.push(r)
                }
            }
            paragraphRoot.citationRanges = result
        }
    }

    // Snap guard reset — fires after event loop to reset guard
    Timer {
        id: snapGuardReset
        interval: 0
        onTriggered: {
            paragraphRoot.snappingGuard = 0
        }
    }

    // Overlay: render opaque badges on top of @citekey markers
    Repeater {
        model: citationRanges

        Rectangle {
            required property var modelData
            x: modelData.rect.x
            y: modelData.rect.y
            width: modelData.rect.width
            height: modelData.rect.height
            radius: 4
            color: badgeMouse.containsMouse ? "#BBDEFB" : "#E3F2FD"
            border.color: "#90CAF9"
            border.width: 1
            opacity: 1.0

            Behavior on color {
                ColorAnimation { duration: 100 }
            }

            Label {
                anchors.centerIn: parent
                text: modelData.display
                font.pixelSize: 11
                font.bold: true
                color: "#1565C0"
            }

            MouseArea {
                id: badgeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    paragraphArea.forceActiveFocus()
                    paragraphArea.select(modelData.start, modelData.end)
                }
            }
        }
    }

    // Forward activeFocus so BlockDelegate.isFocused works
    property bool hasFocus: paragraphArea.activeFocus

    // Allow external code to force focus into the text area
    function forceActiveFocus() {
        paragraphArea.forceActiveFocus()
    }
}
