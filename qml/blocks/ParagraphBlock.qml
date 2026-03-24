import QtQuick
import QtQuick.Controls

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
                root.activeParagraphIndex = blockIndex
                root.activeCursorPosition = cursorPosition
            }
        }

        onCursorPositionChanged: {
            if (activeFocus) {
                var cit = paragraphRoot.citationAt(cursorPosition)
                if (cit !== null && paragraphRoot.snappingGuard < 2) {
                    paragraphRoot.snappingGuard++
                    // Snap to nearest boundary: start or snapEnd (past trailing space)
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
                root.activeCursorPosition = cursorPosition
            }
        }

        onWidthChanged: overlayTimer.restart()
        onContentSizeChanged: overlayTimer.restart()

        Keys.onPressed: function(event) {
            var pos = paragraphArea.cursorPosition

            // Block character input that would modify a citation
            if (event.text.length > 0) {
                // Inside a citation — block all input
                var citInside = paragraphRoot.citationAt(pos)
                if (citInside !== null) {
                    event.accepted = true
                    return
                }
                // At citation end — word chars would extend the @key
                var citAtEnd = paragraphRoot.citationEndingAt(pos)
                if (citAtEnd !== null && /[\w\-]/.test(event.text)) {
                    event.accepted = true
                    return
                }
            }

            if (event.key === Qt.Key_Right) {
                var citAtStart = paragraphRoot.citationStartingAt(pos)
                if (citAtStart !== null) {
                    paragraphArea.cursorPosition = citAtStart.snapEnd
                    event.accepted = true
                    return
                }
            }

            if (event.key === Qt.Key_Left) {
                var citAtEnd = paragraphRoot.citationEndingAt(pos)
                if (citAtEnd !== null) {
                    paragraphArea.cursorPosition = citAtEnd.start
                    event.accepted = true
                    return
                }
                // Also handle cursor at snapEnd (past trailing space)
                var citAtSnap = paragraphRoot.citationSnapEndAt(pos)
                if (citAtSnap !== null) {
                    paragraphArea.cursorPosition = citAtSnap.start
                    event.accepted = true
                    return
                }
            }

            if (event.key === Qt.Key_Backspace) {
                var citBack = paragraphRoot.citationEndingAt(pos)
                    || paragraphRoot.citationSnapEndAt(pos)
                    || paragraphRoot.citationAt(pos)
                if (citBack !== null) {
                    paragraphArea.remove(citBack.start, citBack.end)
                    event.accepted = true
                    return
                }
            }

            if (event.key === Qt.Key_Delete) {
                var citDel = paragraphRoot.citationStartingAt(pos)
                    || paragraphRoot.citationAt(pos)
                if (citDel !== null) {
                    paragraphArea.remove(citDel.start, citDel.end)
                    event.accepted = true
                    return
                }
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
        interval: 0
        onTriggered: {
            paragraphRoot.citationRanges = paragraphRoot.parseCiteKeys()
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

    // Parse @citekey positions from the TextArea's actual text
    function parseCiteKeys() {
        var results = []
        var content = paragraphArea.text
        var re = /@([\w][\w-]*)/g
        var match
        while ((match = re.exec(content)) !== null) {
            var startPos = match.index
            var endPos = match.index + match[0].length
            if (endPos > paragraphArea.length) continue
            // snapEnd extends past trailing space so cursor lands beyond
            // the delimiter — typing there won't extend the @key regex
            var snapEnd = endPos
            if (snapEnd < content.length && content[snapEnd] === ' ')
                snapEnd++
            var r1 = paragraphArea.positionToRectangle(startPos)
            var r2 = paragraphArea.positionToRectangle(endPos)
            // Only overlay if the match is on a single line
            if (Math.abs(r1.y - r2.y) < 2) {
                var w = Math.max(r2.x - r1.x, 30)
                results.push({
                    rect: Qt.rect(r1.x, r1.y, w, r1.height),
                    display: "@" + match[1],
                    start: startPos,
                    end: endPos,
                    snapEnd: snapEnd,
                    key: match[1]
                })
            }
        }
        return results
    }

    // Lookup helpers for citationRanges
    // citationAt uses snapEnd so cursor at @key boundary or trailing
    // space is treated as inside — snapping will push cursor past it
    function citationAt(pos) {
        for (var i = 0; i < citationRanges.length; i++) {
            var c = citationRanges[i]
            if (pos > c.start && pos < c.snapEnd) return c
        }
        return null
    }

    function citationStartingAt(pos) {
        for (var i = 0; i < citationRanges.length; i++) {
            if (citationRanges[i].start === pos) return citationRanges[i]
        }
        return null
    }

    function citationEndingAt(pos) {
        for (var i = 0; i < citationRanges.length; i++) {
            if (citationRanges[i].end === pos) return citationRanges[i]
        }
        return null
    }

    function citationSnapEndAt(pos) {
        for (var i = 0; i < citationRanges.length; i++) {
            if (citationRanges[i].snapEnd === pos && citationRanges[i].snapEnd !== citationRanges[i].end)
                return citationRanges[i]
        }
        return null
    }

    // Forward activeFocus so BlockDelegate.isFocused works
    property bool hasFocus: paragraphArea.activeFocus

    // Allow external code to force focus into the text area
    function forceActiveFocus() {
        paragraphArea.forceActiveFocus()
    }
}
