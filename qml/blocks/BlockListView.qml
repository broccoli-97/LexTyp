import QtQuick
import QtQuick.Controls

ListView {
    id: blockListView
    clip: true
    spacing: 2
    cacheBuffer: 2000

    property var sourceModel

    model: sourceModel
    delegate: BlockDelegate {}

    // ── Focus management ──────────────────────────────────────────────────
    // Focus a specific block's text input after model changes
    function focusBlock(row) {
        focusTimer.targetRow = row
        focusTimer.restart()
    }

    Timer {
        id: focusTimer
        interval: 50
        property int targetRow: -1
        onTriggered: {
            if (targetRow < 0 || targetRow >= blockListView.count) return
            var item = blockListView.itemAtIndex(targetRow)
            if (!item) {
                // Item may not be instantiated yet, scroll to it first
                blockListView.positionViewAtIndex(targetRow, ListView.Contain)
                retryTimer.restart()
                return
            }
            focusBlockItem(item)
        }
    }

    Timer {
        id: retryTimer
        interval: 50
        onTriggered: {
            var item = blockListView.itemAtIndex(focusTimer.targetRow)
            if (item) focusBlockItem(item)
        }
    }

    function focusBlockItem(delegateItem) {
        // The delegate has a Loader (plainLoader or cardLoader) whose item has forceActiveFocus
        // Walk the children to find the loaded block component
        var loader = findLoader(delegateItem)
        if (loader && loader.item && loader.item.forceActiveFocus) {
            loader.item.forceActiveFocus()
        }
    }

    function findLoader(item) {
        // Search for a Loader with a loaded item that has forceActiveFocus
        for (var i = 0; i < item.children.length; i++) {
            var child = item.children[i]
            // Check if it's a RowLayout (contentRow)
            for (var j = 0; j < child.children.length; j++) {
                var inner = child.children[j]
                for (var k = 0; k < inner.children.length; k++) {
                    var loader = inner.children[k]
                    if (loader.item && loader.item.forceActiveFocus) {
                        return loader
                    }
                }
            }
        }
        return null
    }

    Connections {
        target: documentModel
        function onFocusRequested(row) {
            blockListView.focusBlock(row)
        }
    }

    // ── Drag state ──────────────────────────────────────────────────────────
    property bool dragActive: false
    property int dragSourceIndex: -1
    property int dragTargetIndex: -1

    function startDrag(sourceIndex, mouseListY, delegateCard) {
        dragSourceIndex = sourceIndex
        dragTargetIndex = -1
        dragActive = true
        interactive = false

        // Capture static ghost snapshot
        delegateCard.grabToImage(function(result) {
            ghostImage.source = result.url
            ghostOverlay.height = delegateCard.height
        })
        ghostOverlay.ghostY = mouseListY - delegateCard.height / 2

        documentModel.setSerializationEnabled(false)
    }

    function updateDrag(mouseListY) {
        // Position the ghost
        ghostOverlay.ghostY = mouseListY - ghostOverlay.height / 2

        // O(1) drop target detection via indexAt
        var contentMouseY = mouseListY + contentY
        var idx = indexAt(width / 2, contentMouseY)

        if (idx === -1) {
            // Past the end of the list or in spacing gap
            // Check if we're below all items
            if (count > 0) {
                var lastItem = itemAtIndex(count - 1)
                if (lastItem) {
                    var lastBottom = lastItem.mapToItem(blockListView, 0, 0).y + lastItem.height
                    if (mouseListY > lastBottom) {
                        idx = count  // past end
                    } else {
                        // In a gap between items — find nearest by checking neighbors of last known target
                        idx = dragTargetIndex >= 0 ? Math.min(dragTargetIndex, count - 1) : dragSourceIndex
                    }
                }
            }
        }

        if (idx >= 0 && idx < count) {
            var item = itemAtIndex(idx)
            if (item) {
                var itemY = item.mapToItem(blockListView, 0, 0).y
                var itemCenter = itemY + item.height / 2
                dragTargetIndex = (mouseListY < itemCenter) ? idx : idx + 1
            }
        } else if (idx >= count) {
            dragTargetIndex = count
        }

        // Hide indicator for no-op positions (dropping back to same spot)
        if (dragTargetIndex === dragSourceIndex || dragTargetIndex === dragSourceIndex + 1) {
            dragTargetIndex = -1
        }

        // Auto-scroll near edges
        var edgeZone = 60
        if (mouseListY < edgeZone) {
            autoScrollTimer.scrollSpeed = -Math.max(2, (edgeZone - mouseListY) / 3)
        } else if (mouseListY > height - edgeZone) {
            autoScrollTimer.scrollSpeed = Math.max(2, (mouseListY - (height - edgeZone)) / 3)
        } else {
            autoScrollTimer.scrollSpeed = 0
        }
    }

    function endDrag() {
        autoScrollTimer.scrollSpeed = 0

        if (dragActive && dragTargetIndex >= 0 && dragTargetIndex !== dragSourceIndex) {
            // Adjust target: moveNode uses direct target index, not insertion index
            var effectiveTarget = dragTargetIndex > dragSourceIndex
                ? dragTargetIndex - 1
                : dragTargetIndex
            documentModel.moveNode(dragSourceIndex, effectiveTarget)
        }

        dragActive = false
        dragSourceIndex = -1
        dragTargetIndex = -1
        interactive = true
        ghostImage.source = ""

        documentModel.setSerializationEnabled(true)
    }

    // ── Auto-scroll timer ───────────────────────────────────────────────────
    Timer {
        id: autoScrollTimer
        interval: 16
        repeat: true
        running: blockListView.dragActive

        property real scrollSpeed: 0

        onTriggered: {
            if (scrollSpeed === 0) return
            blockListView.contentY = Math.max(0,
                Math.min(blockListView.contentHeight - blockListView.height,
                         blockListView.contentY + scrollSpeed))
        }
    }

    // ── Drop indicator ──────────────────────────────────────────────────────
    Rectangle {
        id: dropIndicator
        visible: blockListView.dragActive && blockListView.dragTargetIndex >= 0
        width: parent.width - 32
        height: 3
        x: 16
        radius: 1.5
        color: "#2979FF"
        z: 99

        y: {
            if (!visible) return 0

            var targetIdx = blockListView.dragTargetIndex
            if (targetIdx >= blockListView.count) {
                // Past end — position after last item
                var lastItem = blockListView.itemAtIndex(blockListView.count - 1)
                if (lastItem) {
                    var pos = lastItem.mapToItem(blockListView, 0, 0)
                    return pos.y + lastItem.height + blockListView.spacing / 2
                }
                return 0
            }

            var item = blockListView.itemAtIndex(targetIdx)
            if (item) {
                var itemPos = item.mapToItem(blockListView, 0, 0)
                return itemPos.y - blockListView.spacing / 2
            }
            return 0
        }
    }

    // ── Ghost overlay ───────────────────────────────────────────────────────
    Item {
        id: ghostOverlay
        visible: blockListView.dragActive
        z: 100
        width: blockListView.width - 16
        x: 8
        opacity: 0.85

        property real ghostY: 0
        y: ghostY

        Image {
            id: ghostImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
        }

        // Subtle drop shadow
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 3
            anchors.leftMargin: 3
            anchors.rightMargin: -3
            anchors.bottomMargin: -3
            color: "#20000000"
            radius: 10
            z: -1
        }
    }

    // ── Transitions ─────────────────────────────────────────────────────────

    // Dragged item jumps instantly
    move: Transition {
        NumberAnimation { properties: "x,y"; duration: 0 }
    }

    // Other blocks slide smoothly — disabled during drag
    displaced: Transition {
        enabled: !blockListView.dragActive
        NumberAnimation { properties: "x,y"; duration: 250; easing.type: Easing.OutCubic }
    }

    add: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 250 }
            NumberAnimation { property: "y"; from: -20; duration: 250; easing.type: Easing.OutCubic }
        }
    }

    remove: Transition {
        SequentialAnimation {
            NumberAnimation { property: "opacity"; to: 0; duration: 200 }
            NumberAnimation { property: "height"; to: 0; duration: 150; easing.type: Easing.InQuad }
        }
    }

    addDisplaced: Transition {
        NumberAnimation { properties: "x,y"; duration: 300; easing.type: Easing.OutCubic }
    }

    removeDisplaced: Transition {
        NumberAnimation { properties: "x,y"; duration: 300; easing.type: Easing.OutCubic }
    }

    // Placeholder when empty
    Column {
        anchors.centerIn: parent
        spacing: 8
        visible: blockListView.count === 0

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No blocks yet"
            font.pixelSize: 14
            color: "#BDBDBD"
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Type / to insert a block"
            font.pixelSize: 12
            color: "#BDBDBD"
        }
    }
}
