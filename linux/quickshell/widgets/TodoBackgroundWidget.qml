pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "todo"

    // Disable whole-widget drag — we use a header-only drag handle so task
    // buttons and the ListView remain fully interactive.
    draggable: false
    propagateComposedEvents: true

    implicitWidth:  card.implicitWidth
    implicitHeight: card.implicitHeight

    // ─── State ──────────────────────────────────────────────────────────────
    readonly property var pendingTasks: Todo.list
        .map(function(item, i) { return Object.assign({}, item, { originalIndex: i }); })
        .filter(function(item) { return !item.done; })

    readonly property var displayTasks: Todo.list
        .map(function(item, i) { return Object.assign({}, item, { originalIndex: i }); })
        .sort(function(a, b) {
            if (a.done === b.done) return a.originalIndex - b.originalIndex;
            return a.done ? 1 : -1;
        })

    property bool addInputVisible:  false
    property bool selectionMode:    false
    property var  selectedIndices:  []   // list of originalIndex values

    // ─── Helpers ────────────────────────────────────────────────────────────
    function submitNewTask() {
        const txt = newTaskField.text.trim();
        if (txt.length === 0) return;
        Todo.addTask(txt);
        newTaskField.text = "";
        root.addInputVisible = false;
    }

    function toggleSelection(originalIndex) {
        let s = root.selectedIndices.slice();
        const pos = s.indexOf(originalIndex);
        if (pos === -1) s.push(originalIndex);
        else            s.splice(pos, 1);
        root.selectedIndices = s;
    }

    function isSelected(originalIndex) {
        return root.selectedIndices.indexOf(originalIndex) !== -1;
    }

    function selectAll() {
        root.selectedIndices = root.displayTasks.map(function(t) { return t.originalIndex; });
    }

    function clearSelection() {
        root.selectedIndices = [];
        root.selectionMode = false;
    }

    function deleteSelected() {
        // Delete from highest index to lowest so indices stay valid
        const sorted = root.selectedIndices.slice().sort(function(a,b){ return b - a; });
        for (const idx of sorted) Todo.deleteItem(idx);
        root.clearSelection();
    }

    function markSelectedDone() {
        const sorted = root.selectedIndices.slice().sort(function(a,b){ return b - a; });
        for (const idx of sorted) Todo.markDone(idx);
        root.clearSelection();
    }

    // ─── Shadow ──────────────────────────────────────────────────────────────
    StyledRectangularShadow { target: card }

    // ─── Card ────────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        implicitWidth: 318
        implicitHeight: cardCol.implicitHeight
        radius: 20
        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.12)
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.55)
        clip: true

        ColumnLayout {
            id: cardCol
            anchors { top: parent.top; left: parent.left; right: parent.right }
            spacing: 0

            // ─────────────────────────────────────────────────────────────
            // HEADER — drag handle + title + action buttons
            // Engineering: drag MouseArea declared FIRST (lower z-order) so
            // buttons declared after naturally receive clicks first.
            // ─────────────────────────────────────────────────────────────
            Item {
                id: headerItem
                Layout.fillWidth: true
                implicitHeight: headerRow.implicitHeight + 20

                // Header background
                Rectangle {
                    anchors.fill: parent
                    radius: card.radius
                    color: root.selectionMode
                        ? ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, 0.25)
                        : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer,   0.28)
                    Behavior on color { ColorAnimation { duration: 200 } }
                    // Square off bottom edge while keeping top corners rounded
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: card.radius
                        color: parent.color
                    }
                }

                // ── Drag handle (FIRST = lower z) ───────────────────────
                MouseArea {
                    anchors.fill: parent
                    drag.target: root
                    drag.minimumX: 0
                    drag.minimumY: 0
                    drag.maximumX: Math.max(0, root.scaledScreenWidth  - root.width)
                    drag.maximumY: Math.max(0, root.scaledScreenHeight - root.height)
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    onReleased: {
                        root.targetX    = root.x;
                        root.targetY    = root.y;
                        root.configEntry.x = root.targetX;
                        root.configEntry.y = root.targetY;
                    }
                    // Close overflow menu on drag-start
                    onPressed: overflowMenu.close()
                }

                // ── Header row content (SECOND = higher z, clicks first) ─
                RowLayout {
                    id: headerRow
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 12; rightMargin: 6
                    }
                    spacing: 6

                    // Header content begins here

                    // In selection mode show a "select all" checkbox; otherwise the icon
                    RippleButton {
                        visible: root.selectionMode
                        implicitWidth: 28; implicitHeight: 28
                        buttonRadius: Appearance.rounding.full
                        onClicked: {
                            if (root.selectedIndices.length === root.displayTasks.length)
                                root.selectedIndices = [];
                            else
                                root.selectAll();
                        }
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: root.selectedIndices.length === root.displayTasks.length
                                ? "check_box" : "check_box_outline_blank"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                    }

                    MaterialSymbol {
                        visible: !root.selectionMode
                        text: "checklist"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colPrimary
                    }

                    RippleButton {
                        id: listSelectorBtn
                        visible: !root.selectionMode && Todo.lists.length > 0
                        implicitHeight: 30; Layout.fillWidth: false
                        buttonRadius: Appearance.rounding.small
                        onClicked: Todo.lists.length > 1 ? listSelectorMenu.open() : null
                        contentItem: RowLayout {
                            spacing: 4
                            StyledText {
                                text: {
                                    const l = Todo.lists.find(function(x) { return x.id === Todo.currentListId; });
                                    return l ? l.title : Translation.tr("To Do");
                                }
                                font.pixelSize: Appearance.font.pixelSize.large
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colPrimary
                            }
                            MaterialSymbol {
                                visible: Todo.lists.length > 1
                                text: "arrow_drop_down"
                                iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colPrimary
                            }
                        }

                        Popup {
                            id: listSelectorMenu
                            y: listSelectorBtn.height + 4
                            padding: 4
                            background: Rectangle {
                                implicitWidth: 160
                                color: Appearance.colors.colLayer1
                                radius: Appearance.rounding.small
                                border.width: 1
                                border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.4)
                            }
                            contentItem: ColumnLayout {
                                spacing: 2
                                Repeater {
                                    model: Todo.lists
                                    MenuButton {
                                        Layout.fillWidth: true
                                        buttonText: modelData.title
                                        onClicked: { listSelectorMenu.close(); Todo.switchList(modelData.id); }
                                    }
                                }
                            }
                        }
                    }

                    StyledText {
                        visible: root.selectionMode || Todo.lists.length === 0
                        text: root.selectionMode
                            ? (root.selectedIndices.length > 0
                                ? Translation.tr("%1 selected").arg(root.selectedIndices.length)
                                : Translation.tr("Select tasks"))
                            : Translation.tr("To Do")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        color: root.selectionMode
                            ? Appearance.colors.colOnSecondaryContainer
                            : Appearance.colors.colPrimary
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }

                    // Task count badge (hidden in selection mode)
                    Rectangle {
                        visible: !root.selectionMode && root.pendingTasks.length > 0
                        implicitWidth: Math.max(badgeLabel.implicitWidth + 10, 22)
                        implicitHeight: 22
                        radius: 11
                        color: Appearance.colors.colPrimary
                        Behavior on implicitWidth { NumberAnimation { duration: 120 } }

                        StyledText {
                            id: badgeLabel
                            anchors.centerIn: parent
                            text: root.pendingTasks.length
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnPrimary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // + / × add-task toggle (hidden in selection mode)
                    RippleButton {
                        visible: !root.selectionMode
                        implicitWidth: 30; implicitHeight: 30
                        buttonRadius: Appearance.rounding.small
                        onClicked: {
                            overflowMenu.close();
                            root.addInputVisible = !root.addInputVisible;
                            if (root.addInputVisible) newTaskField.forceActiveFocus();
                        }
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: root.addInputVisible ? "close" : "add"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }

                    // ⋮ overflow menu button
                    RippleButton {
                        id: overflowBtn
                        implicitWidth: 30; implicitHeight: 30
                        buttonRadius: Appearance.rounding.small
                        onClicked: {
                            if (overflowMenu.visible) overflowMenu.close();
                            else                      overflowMenu.open();
                        }
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "more_vert"
                            iconSize: Appearance.font.pixelSize.normal
                            color: root.selectionMode
                                ? Appearance.colors.colOnSecondaryContainer
                                : Appearance.colors.colOnPrimaryContainer
                        }

                        // ── Overflow dropdown (Popup anchored to this button) ──
                        Popup {
                            id: overflowMenu
                            y: overflowBtn.height + 4
                            x: overflowBtn.width - implicitWidth
                            z: 999
                            padding: 0
                            modal: false
                            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                            background: Rectangle {
                                implicitWidth: menuCol.implicitWidth
                                implicitHeight: menuCol.implicitHeight
                                color: Appearance.colors.colLayer1
                                radius: Appearance.rounding.small
                                border.width: 1
                                border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.4)
                            }

                            contentItem: ColumnLayout {
                                id: menuCol
                                spacing: 0

                                // ─ Select tasks ─
                                MenuButton {
                                    Layout.fillWidth: true
                                    buttonText: root.selectionMode
                                        ? Translation.tr("Exit selection")
                                        : Translation.tr("Select tasks")
                                    onClicked: {
                                        overflowMenu.close();
                                        if (root.selectionMode) root.clearSelection();
                                        else { root.selectionMode = true; root.addInputVisible = false; }
                                    }
                                }

                                // ─ Select all ─
                                MenuButton {
                                    Layout.fillWidth: true
                                    buttonText: Translation.tr("Select all")
                                    enabled: root.pendingTasks.length > 0
                                    onClicked: {
                                        overflowMenu.close();
                                        root.selectionMode = true;
                                        root.addInputVisible = false;
                                        root.selectAll();
                                    }
                                }

                                // Separator
                                Rectangle {
                                    Layout.fillWidth: true; height: 1
                                    color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.6)
                                }

                                // ─ Mark all done ─
                                MenuButton {
                                    Layout.fillWidth: true
                                    buttonText: Translation.tr("Mark all done")
                                    enabled: root.pendingTasks.length > 0
                                    onClicked: {
                                        overflowMenu.close();
                                        // Mark done from highest to lowest index
                                        const idxs = root.pendingTasks
                                            .map(function(t){ return t.originalIndex; })
                                            .sort(function(a,b){ return b-a; });
                                        for (const i of idxs) Todo.markDone(i);
                                        root.clearSelection();
                                    }
                                }

                                // ─ Delete all tasks ─
                                MenuButton {
                                    Layout.fillWidth: true
                                    buttonText: Translation.tr("Delete all tasks")
                                    enabled: root.pendingTasks.length > 0
                                    onClicked: {
                                        overflowMenu.close();
                                        const idxs = root.pendingTasks
                                            .map(function(t){ return t.originalIndex; })
                                            .sort(function(a,b){ return b-a; });
                                        for (const i of idxs) Todo.deleteItem(i);
                                        root.clearSelection();
                                    }
                                }

                                // ─ Delete finished tasks ─
                                MenuButton {
                                    Layout.fillWidth: true
                                    buttonText: Translation.tr("Delete finished tasks")
                                    enabled: root.displayTasks.length > root.pendingTasks.length
                                    onClicked: {
                                        overflowMenu.close();
                                        const idxs = Todo.list
                                            .map(function(t, i) { return {done: t.done, idx: i}; })
                                            .filter(function(t) { return t.done; })
                                            .map(function(t) { return t.idx; })
                                            .sort(function(a,b) { return b-a; });
                                        for (const i of idxs) Todo.deleteItem(i);
                                        root.clearSelection();
                                    }
                                }

                                // Separator
                                Rectangle {
                                    Layout.fillWidth: true; height: 1
                                    color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.6)
                                }

                                // ─ Sync with Google Tasks ─
                                MenuButton {
                                    Layout.fillWidth: true
                                    buttonText: root.isSyncing
                                        ? Translation.tr("Syncing…")
                                        : Translation.tr("Sync with Google Tasks")
                                    enabled: !root.isSyncing
                                    onClicked: {
                                        overflowMenu.close();
                                        root.triggerDebouncedSync();
                                    }
                                }

                                // ─ Refresh from disk ─
                                MenuButton {
                                    Layout.fillWidth: true
                                    buttonText: Translation.tr("Refresh from disk")
                                    onClicked: { overflowMenu.close(); Todo.refresh(); }
                                }

                                // ─ Delete Widget (Temporary Hide) ─
                                MenuButton {
                                    Layout.fillWidth: true
                                    buttonText: Translation.tr("Delete Widget")
                                    textColor: Appearance.colors.colError
                                    onClicked: {
                                        overflowMenu.close();
                                        root.visible = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ─── Divider ──────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true; height: 1
                color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.65)
            }

            // ─── Bulk-action bar (visible only in selection mode) ─────────
            Item {
                Layout.fillWidth: true
                implicitHeight: root.selectionMode ? bulkRow.implicitHeight + 12 : 0
                clip: true
                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }

                RowLayout {
                    id: bulkRow
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10; rightMargin: 10
                    }
                    spacing: 8
                    visible: root.selectionMode

                    // Mark done
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        buttonRadius: Appearance.rounding.small
                        enabled: root.selectedIndices.length > 0
                        colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.3)
                        colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                        colRipple: Appearance.colors.colPrimaryContainerActive
                        onClicked: root.markSelectedDone()
                        contentItem: RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol {
                                text: "check"; iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: Translation.tr("Done")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colPrimary
                            }
                        }
                    }

                    // Delete selected
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        buttonRadius: Appearance.rounding.small
                        enabled: root.selectedIndices.length > 0
                        colBackground: ColorUtils.transparentize(Appearance.colors.colErrorContainer, 0.3)
                        colBackgroundHover: Appearance.colors.colErrorContainerHover
                        colRipple: Appearance.colors.colErrorContainerActive
                        onClicked: root.deleteSelected()
                        contentItem: RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            MaterialSymbol {
                                text: "delete"; iconSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colError
                            }
                            StyledText {
                                text: Translation.tr("Delete")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colError
                            }
                        }
                    }

                    // Cancel
                    RippleButton {
                        implicitWidth: 34; implicitHeight: 34
                        buttonRadius: Appearance.rounding.small
                        onClicked: root.clearSelection()
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"; iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: root.selectionMode ? 1 : 0
                color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.65)
                Behavior on height { NumberAnimation { duration: 120 } }
            }

            // ─── Add-task input (collapsible) ─────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: root.addInputVisible ? inputRow.implicitHeight + 16 : 0
                clip: true
                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }

                RowLayout {
                    id: inputRow
                    anchors {
                        left: parent.left; right: parent.right
                        top: parent.top; topMargin: 8
                        leftMargin: 10; rightMargin: 8
                    }
                    spacing: 6
                    visible: root.addInputVisible

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer2
                        border.width: 1
                        border.color: newTaskField.activeFocus
                            ? Appearance.colors.colPrimary
                            : ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.4)
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        TextField {
                            id: newTaskField
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            placeholderText: Translation.tr("New task…")
                            placeholderTextColor: Appearance.colors.colSubtext
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.normal
                            background: null
                            Keys.onEscapePressed: { root.addInputVisible = false; text = ""; }
                            onAccepted: root.submitNewTask()
                        }
                    }

                    RippleButton {
                        implicitWidth: 36; implicitHeight: 36
                        buttonRadius: Appearance.rounding.small
                        enabled: newTaskField.text.trim().length > 0
                        onClicked: root.submitNewTask()
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "check"; iconSize: Appearance.font.pixelSize.normal
                            color: newTaskField.text.trim().length > 0
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colSubtext
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: root.addInputVisible ? 1 : 0
                color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.65)
                Behavior on height { NumberAnimation { duration: 120 } }
            }

            // ─── Task list ────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: Math.min(300, Math.max(80, 
                    root.displayTasks.length === 0 ? 80 : root.displayTasks.length * 62 + 16))
                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }

                // Empty state
                ColumnLayout {
                    anchors.centerIn: parent
                    opacity: root.displayTasks.length === 0 ? 1 : 0
                    visible: opacity > 0
                    spacing: 6
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        iconSize: 44; text: "check_circle"
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("All done!")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }
                }

                ListView {
                    id: taskListView
                    anchors { fill: parent; margins: 8 }
                    spacing: 6
                    clip: true
                    visible: root.displayTasks.length > 0
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    model: ScriptModel { values: root.displayTasks }

                    delegate: Column {
                        id: taskDelegate
                        width: taskListView.width
                        required property var modelData
                        required property int index

                        readonly property bool isFirstDone: modelData && modelData.done && (index === 0 || !root.displayTasks[index - 1] || !root.displayTasks[index - 1].done)

                        // Visual separator for Completed tasks
                        Item {
                            width: parent.width
                            implicitHeight: taskDelegate.isFirstDone ? 36 : 0
                            visible: taskDelegate.isFirstDone
                            clip: true

                            RowLayout {
                                anchors { fill: parent; leftMargin: 8; rightMargin: 8; topMargin: 12; bottomMargin: 4 }
                                spacing: 12
                                Rectangle {
                                    Layout.fillWidth: true; height: 1
                                    color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.4)
                                }
                                StyledText {
                                    text: Translation.tr("Completed")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                    font.weight: Font.DemiBold
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 1
                                    color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.4)
                                }
                            }
                        }

                        Rectangle {
                            id: taskRow

                            readonly property bool checked: root.selectedIndices.indexOf(taskDelegate.modelData.originalIndex) !== -1

                        implicitHeight: rowContent.implicitHeight + 12
                        radius: Appearance.rounding.small
                        color: taskRow.checked
                            ? ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, 0.25)
                            : (rowHover.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        
                        // Subtask indentation
                        anchors.left: parent.left
                        anchors.leftMargin: taskDelegate.modelData.parent ? 28 : 0
                        width: parent.width - anchors.leftMargin

                        // Drag & Drop
                        Drag.active: dragHandler.active
                        Drag.source: taskDelegate
                        Drag.hotSpot.x: width / 2
                        Drag.hotSpot.y: height / 2

                        DropArea {
                            anchors.fill: parent
                            onDropped: (drop) => {
                                if (drop.source && drop.source.modelData) {
                                    const fromIdx = drop.source.modelData.originalIndex;
                                    const toIdx = taskDelegate.modelData.originalIndex;
                                    if (fromIdx !== toIdx) {
                                        Todo.moveItem(fromIdx, toIdx);
                                    }
                                }
                            }
                        }

                        HoverHandler { id: rowHover }

                        RowLayout {
                            id: rowContent
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 8; rightMargin: 6
                            }
                            spacing: 8
                            
                            // Drag Handle
                            MaterialSymbol {
                                visible: !root.selectionMode && !taskDelegate.modelData.done
                                text: "drag_indicator"
                                color: dragHandler.active ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                                iconSize: Appearance.font.pixelSize.normal
                                Layout.alignment: Qt.AlignVCenter
                                
                                DragHandler {
                                    id: dragHandler
                                    target: taskRow
                                    xAxis.enabled: false
                                    onActiveChanged: {
                                        if (active) {
                                            taskRow.z = 100;
                                            taskRow.opacity = 0.8;
                                        } else {
                                            taskRow.z = 1;
                                            taskRow.opacity = 1.0;
                                            taskRow.y = 0; // Reset position, delegate model will sort it out
                                            taskRow.Drag.drop();
                                        }
                                    }
                                }
                            }

                            // In selection mode: checkbox. Otherwise: check button.
                            RippleButton {
                                Layout.fillWidth: false
                                implicitWidth: 30; implicitHeight: 30
                                buttonRadius: Appearance.rounding.full
                                onClicked: {
                                    if (root.selectionMode)
                                        root.toggleSelection(taskDelegate.modelData.originalIndex);
                                    else {
                                        if (taskDelegate.modelData.done)
                                            Todo.markUnfinished(taskDelegate.modelData.originalIndex);
                                        else
                                            Todo.markDone(taskDelegate.modelData.originalIndex);
                                    }
                                }
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: root.selectionMode
                                        ? (taskRow.checked ? "check_box" : "check_box_outline_blank")
                                        : (taskDelegate.modelData.done ? "task_alt" : "radio_button_unchecked")
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: root.selectionMode
                                        ? (taskRow.checked ? Appearance.colors.colSecondary : Appearance.colors.colSubtext)
                                        : (taskDelegate.modelData.done ? Appearance.colors.colSubtext : Appearance.colors.colPrimary)
                                }
                            }

                            // Task text and Due date
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    Layout.fillWidth: true
                                    text: taskDelegate.modelData.content
                                    wrapMode: Text.WordWrap
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.strikeout: taskDelegate.modelData.done
                                    color: taskDelegate.modelData.done ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1
                                    opacity: taskDelegate.modelData.done ? 0.6 : 1.0
                                }

                                StyledText {
                                    visible: !!taskDelegate.modelData.due
                                    Layout.fillWidth: true
                                    text: {
                                        if (!taskDelegate.modelData.due) return "";
                                        const dueDate = new Date(taskDelegate.modelData.due);
                                        const now = new Date();
                                        const isOverdue = dueDate < now && !taskDelegate.modelData.done;
                                        return (isOverdue ? "⚠️ Overdue: " : "📅 Due: ") + dueDate.toLocaleDateString();
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: {
                                        if (taskDelegate.modelData.done) return Appearance.colors.colSubtext;
                                        const dueDate = new Date(taskDelegate.modelData.due);
                                        return (dueDate < new Date()) ? Appearance.colors.colError : Appearance.colors.colSubtext;
                                    }
                                }
                            }

                            // Delete button — hover-reveal in normal mode, always in selection mode
                            RippleButton {
                                Layout.fillWidth: false
                                implicitWidth: 28; implicitHeight: 28
                                buttonRadius: Appearance.rounding.full
                                visible: !root.selectionMode
                                opacity: rowHover.containsMouse ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                onClicked: Todo.deleteItem(taskDelegate.modelData.originalIndex)
                                StyledToolTip { text: Translation.tr("Delete task") }
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "delete"; iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colError
                                }
                            }
                        }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true; implicitHeight: 8 }
        }
    }
}
