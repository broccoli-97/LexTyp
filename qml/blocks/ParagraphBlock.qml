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

    // Slash menu state
    property bool slashActive: false
    property int slashStartPos: -1
    property bool slashPending: false

    implicitHeight: paragraphArea.implicitHeight

    TextArea {
        id: paragraphArea
        anchors.fill: parent

        placeholderText: "Type / for commands\u2026"
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

            // Slash menu handling
            if (paragraphRoot.slashActive) {
                // Check if "/" is still at slashStartPos
                if (paragraphRoot.slashStartPos < text.length &&
                    text[paragraphRoot.slashStartPos] === "/") {
                    // Extract filter: text between "/" and cursor
                    var filterEnd = paragraphArea.cursorPosition
                    if (filterEnd > paragraphRoot.slashStartPos + 1) {
                        slashMenuPopup.filterText = text.substring(
                            paragraphRoot.slashStartPos + 1, filterEnd)
                    } else {
                        slashMenuPopup.filterText = ""
                    }
                } else {
                    // "/" was deleted, close menu
                    paragraphRoot.slashActive = false
                    slashMenuPopup.close()
                }
            } else if (paragraphRoot.slashPending) {
                // "/" was just typed — open menu
                paragraphRoot.slashPending = false
                paragraphRoot.slashActive = true
                paragraphRoot.slashStartPos = paragraphArea.cursorPosition - 1

                // Position popup at cursor
                var rect = paragraphArea.positionToRectangle(paragraphArea.cursorPosition)
                slashMenuPopup.x = Math.max(0, rect.x - 10)
                slashMenuPopup.y = rect.y + rect.height + 4
                slashMenuPopup.filterText = ""
                slashMenuPopup.open()
            }
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

            // Slash menu keyboard navigation
            if (paragraphRoot.slashActive && slashMenuPopup.visible) {
                if (event.key === Qt.Key_Up) {
                    slashMenuPopup.moveUp()
                    event.accepted = true
                    return
                } else if (event.key === Qt.Key_Down) {
                    slashMenuPopup.moveDown()
                    event.accepted = true
                    return
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    slashMenuPopup.selectCurrent()
                    event.accepted = true
                    return
                } else if (event.key === Qt.Key_Escape ||
                           event.key === Qt.Key_Left ||
                           event.key === Qt.Key_Right) {
                    paragraphRoot.slashActive = false
                    slashMenuPopup.close()
                    // Don't consume Left/Right — let them move the cursor
                    if (event.key === Qt.Key_Escape)
                        event.accepted = true
                    return
                }
            }

            // Citation picker keyboard navigation
            if (citationPickerPopup.visible) {
                if (event.key === Qt.Key_Escape) {
                    citationPickerPopup.close()
                    event.accepted = true
                    return
                }
            }

            // Detect "/" key — set pending flag for onTextChanged
            if (event.text === "/" && !paragraphRoot.slashActive) {
                paragraphRoot.slashPending = true
            }

            // Enter — split paragraph at cursor
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                documentModel.splitNode(blockIndex, pos)
                event.accepted = true
                return
            }

            // Backspace at start of empty paragraph — delete block
            if (event.key === Qt.Key_Backspace && pos === 0 &&
                paragraphArea.text.length === 0 && documentModel.nodeCount() > 1) {
                documentModel.removeNode(blockIndex)
                event.accepted = true
                return
            }

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

    // Helper: remove slash command text from the paragraph
    function removeSlashText() {
        var text = paragraphArea.text
        var startPos = paragraphRoot.slashStartPos
        // Find end of slash command (cursor position)
        var endPos = paragraphArea.cursorPosition
        if (startPos < 0) startPos = 0
        if (endPos > text.length) endPos = text.length

        var before = text.substring(0, startPos)
        var after = text.substring(endPos)
        var newText = before + after

        paragraphRoot.updatingFromModel = true
        paragraphArea.text = newText
        paragraphRoot.lastModelContent = newText
        documentModel.setNodeContent(blockIndex, newText)
        paragraphArea.cursorPosition = startPos
        paragraphRoot.updatingFromModel = false

        return { before: before, after: after, insertPos: startPos }
    }

    // React to external model changes (e.g. insertInlineCitation)
    onBlockContentChanged: {
        if (blockContent !== lastModelContent) {
            updatingFromModel = true
            var savedPos = paragraphArea.cursorPosition
            var oldLen = lastModelContent.length
            paragraphArea.text = blockContent
            lastModelContent = blockContent
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
                if (Math.abs(r1.y - r2.y) < 2) {
                    var w = Math.max(r2.x - r1.x, 30)
                    r.rect = Qt.rect(r1.x, r1.y, w, r1.height)
                    result.push(r)
                }
            }
            paragraphRoot.citationRanges = result
        }
    }

    // Snap guard reset
    Timer {
        id: snapGuardReset
        interval: 0
        onTriggered: paragraphRoot.snappingGuard = 0
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

            Behavior on color { ColorAnimation { duration: 100 } }

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

    property bool hasFocus: paragraphArea.activeFocus

    function forceActiveFocus() {
        paragraphArea.forceActiveFocus()
    }

    // Slash command menu
    SlashMenu {
        id: slashMenuPopup
        parent: paragraphRoot

        onItemSelected: function(nodeType, level, isInline) {
            paragraphRoot.slashActive = false
            var savedCursor = paragraphArea.cursorPosition

            if (isInline) {
                // Citation: remove slash text, then open citation picker
                var info = paragraphRoot.removeSlashText()
                citationPickerPopup.insertPosition = info.insertPos
                citationPickerPopup.x = slashMenuPopup.x
                citationPickerPopup.y = slashMenuPopup.y
                citationPickerPopup.open()
            } else {
                // Block type: remove slash text, then create block
                var blockInfo = paragraphRoot.removeSlashText()
                var textBefore = blockInfo.before.trim()
                var textAfter = blockInfo.after.trim()

                if (textBefore.length === 0 && textAfter.length === 0) {
                    // Empty paragraph — convert in place
                    documentModel.changeNodeType(blockIndex, nodeType)
                    if (nodeType === 0 && level > 0)
                        documentModel.setNodeLevel(blockIndex, level)
                } else {
                    // Has content — insert new block below
                    // Keep current para content as-is (slash text already removed)
                    documentModel.insertNodeBelow(blockIndex, nodeType)
                    var newIdx = blockIndex + 1
                    if (nodeType === 0 && level > 0)
                        documentModel.setNodeLevel(newIdx, level)
                }
            }
        }

        onClosed: {
            paragraphRoot.slashActive = false
            if (!citationPickerPopup.visible)
                paragraphArea.forceActiveFocus()
        }
    }

    // Citation picker popup
    CitationPicker {
        id: citationPickerPopup
        parent: paragraphRoot

        property int insertPosition: 0

        onCitationSelected: function(key) {
            documentModel.insertInlineCitation(blockIndex, citationPickerPopup.insertPosition, key)
            paragraphArea.forceActiveFocus()
        }

        onClosed: {
            paragraphArea.forceActiveFocus()
        }
    }
}
