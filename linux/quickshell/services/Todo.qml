pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell;
import Quickshell.Io;
import QtQuick;

/**
 * Simple to-do list manager.
 * Each item is an object with "content" and "done" properties.
 */
Singleton {
    id: root
    property var filePath: Directories.todoPath
    property var fullData: null
    property var lists: []
    property string currentListId: ""
    property var list: []

    function updateFromData() {
        if (!fullData) return;
        lists = fullData.lists || [];
        currentListId = fullData.currentListId || "";
        if (lists.length > 0 && !currentListId) {
            currentListId = lists[0].id;
            fullData.currentListId = currentListId;
        }
        if (currentListId && fullData.tasks && fullData.tasks[currentListId]) {
            list = fullData.tasks[currentListId];
        } else {
            list = [];
        }
    }

    function switchList(listId) {
        if (!fullData) return;
        fullData.currentListId = listId;
        updateFromData();
        saveFile();
    }

    function saveFile() {
        if (!fullData) return;
        if (currentListId) {
            if (!fullData.tasks) fullData.tasks = {};
            fullData.tasks[currentListId] = list;
        }
        todoFileView.watchChanges = false;
        todoFileView.setText(JSON.stringify(fullData, null, 2));
        todoFileView.watchChanges = true;
    }
    
    function addItem(item) {
        list.push(item)
        root.list = list.slice(0)
        saveFile()
    }

    function addTask(desc) {
        const item = {
            "content": desc,
            "done": false,
            "parent": null
        }
        addItem(item)
    }

    function markDone(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = true
            root.list = list.slice(0)
            saveFile()
        }
    }

    function markUnfinished(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = false
            root.list = list.slice(0)
            saveFile()
        }
    }

    function deleteItem(index) {
        if (index >= 0 && index < list.length) {
            list.splice(index, 1)
            root.list = list.slice(0)
            saveFile()
        }
    }

    function moveItem(fromIndex, toIndex) {
        if (fromIndex >= 0 && fromIndex < list.length && toIndex >= 0 && toIndex < list.length) {
            const item = list.splice(fromIndex, 1)[0];
            list.splice(toIndex, 0, item);
            root.list = list.slice(0);
            saveFile();
        }
    }

    function refresh() {
        todoFileView.reload()
    }

    Component.onCompleted: {
        refresh()
    }

    FileView {
        id: todoFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            // Only reload if we aren't the ones currently writing it!
            if (todoFileView.watchChanges) {
                todoFileView.reload()
            }
        }
        onLoaded: {
            try {
                const fileContents = todoFileView.text()
                // Support legacy format gracefully during migration
                let parsed = JSON.parse(fileContents)
                if (Array.isArray(parsed)) {
                    root.fullData = { lists: [{id: "legacy", name: "Legacy Tasks"}], currentListId: "legacy", tasks: {"legacy": parsed} }
                    root.currentListId = "legacy"
                } else {
                    root.fullData = parsed
                }
                root.updateFromData()
                console.log("[To Do] File loaded")
            } catch (e) {
                console.log("[To Do] Parse error: " + e)
            }
        }
        onLoadFailed: (error) => {
            if(error == FileViewError.FileNotFound) {
                console.log("[To Do] File not found, creating new file.")
                root.fullData = { lists: [], currentListId: "", tasks: {} }
                root.updateFromData()
                root.saveFile()
            } else {
                console.log("[To Do] Error loading file: " + error)
            }
        }
    }
}

