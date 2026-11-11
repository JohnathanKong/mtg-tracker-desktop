import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    visible: true
    width: 1460
    height: 930
    minimumWidth: 1040
    minimumHeight: 710
    title: "MTG Tracker Desktop"
    color: "#090E16"

    property string page: "library"
    property string selectedDeck: ""
    property int revision: 0
    property string toastMessage: ""

    function openEditor(id) {
        selectedDeck = id
        page = "editor"
    }
    function toLibrary() {
        page = "library"
        selectedDeck = ""
    }
    function toLinks() {
        page = "links"
        selectedDeck = ""
    }
    function toDevice() {
        page = "device"
        selectedDeck = ""
        deviceSync.refreshPorts()
    }
    function showToast(message) {
        toastMessage = message
        toastTimer.restart()
    }
    function filteredDecks() {
        var touch = revision
        var all = deckStore.allDecks()
        var query = searchField.text.toLowerCase().trim()
        var result = all.filter(function(d) {
            return !query || (d.name || "").toLowerCase().indexOf(query) >= 0 ||
                   (d.commander || "").toLowerCase().indexOf(query) >= 0
        })
        if (sortByName.checked)
            result.sort(function(a, b) { return a.name.localeCompare(b.name) })
        else
            result.reverse()
        return result
    }

    Connections {
        target: deckStore
        function onDecksChanged() { window.revision++ }
        function onErrorOccurred(message) { window.showToast(message) }
    }
    Timer { id: toastTimer; interval: 4300; onTriggered: toastMessage = "" }

    // Thin gold rule anchors the experience instead of standard Windows chrome.
    Rectangle {
        height: 3
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "#9D553F" }
            GradientStop { position: .38; color: "#E7B75E" }
            GradientStop { position: .74; color: "#C1744B" }
            GradientStop { position: 1; color: "#2B2031" }
        }
    }

    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.topMargin: 3
        anchors.left: parent.left
        anchors.right: parent.right
        height: 91
        color: "#0D131D"
        border.color: "#243142"
        border.width: 1

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 28
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14
            Rectangle {
                width: 46; height: 46; radius: 12
                color: "#2B2123"
                border.color: "#886043"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "✦"
                    color: "#F4C46E"
                    font.pixelSize: 31
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: "MTG  TRACKER"
                    color: "#FFF3E4"
                    font.family: "Georgia"
                    font.pixelSize: 25
                    font.bold: true
                    font.letterSpacing: 1
                }
                Text {
                    text: "COMMANDER DECK MANAGER"
                    color: "#9DA8BA"
                    font.family: "Segoe UI"
                    font.pixelSize: 10
                    font.letterSpacing: 2.5
                }
            }
        }
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 28
            anchors.verticalCenter: parent.verticalCenter
            width: 142; height: 32; radius: 16
            color: "#162521"
            border.color: "#355E4F"
            Row {
                anchors.centerIn: parent
                spacing: 8
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 7; height: 7; radius: 4
                    color: "#58D9A6"
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "LOCAL  •  OFFLINE"
                    color: "#98D5B9"
                    font.family: "Segoe UI"
                    font.pixelSize: 10
                    font.bold: true
                }
            }
        }
    }

    Rectangle {
        id: sidebar
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: 214
        color: "#0F151F"
        border.color: "#243142"
        border.width: 1

        Text {
            anchors.left: parent.left; anchors.leftMargin: 24
            y: 29
            text: "WORKSPACE"
            color: "#758399"
            font.family: "Segoe UI"
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 2
        }

        Rectangle {
            id: navLibrary
            x: 12; y: 60
            width: parent.width - 24
            height: 50
            radius: 10
            color: window.page === "library" ? "#25232A" :
                   navLibraryHover.containsMouse ? "#202938" : "transparent"
            border.color: window.page === "library" ? "#6B513A" : "transparent"
            border.width: 1
            Rectangle {
                x: 0; width: 3; height: parent.height
                radius: 2
                color: "#F2BD67"
                visible: window.page === "library"
            }
            Row {
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 13
                Text {
                    text: "▤"
                    color: "#F0C777"
                    font.pixelSize: 22
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "My Decks"
                    color: "#FFF1DC"
                    font.family: "Segoe UI"
                    font.pixelSize: 14
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea {
                id: navLibraryHover
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: window.toLibrary()
            }
        }

        Rectangle {
            id: navCreate
            x: 12; y: 118; width: parent.width - 24
            height: 50; radius: 10
            color: navCreateHover.containsMouse ? "#202938" : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
            Row {
                anchors.left: parent.left; anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 13
                Text {
                    text: "⊕"
                    color: "#C3C0BB"; font.pixelSize: 23
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "New Deck"
                    color: "#CCD5E3"
                    font.family: "Segoe UI"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea {
                id: navCreateHover
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: window.openEditor("")
            }
        }

        Rectangle {
            id: navLinks
            x: 12; y: 176
            width: parent.width - 24
            height: 50
            radius: 10
            color: window.page === "links" ? "#25232A" :
                   linksHover.containsMouse ? "#202938" : "transparent"
            border.color: window.page === "links" ? "#6B513A" : "transparent"
            border.width: 1

            Rectangle {
                x: 0; width: 3; height: parent.height
                radius: 2
                color: "#F2BD67"
                visible: window.page === "links"
            }
            Row {
                anchors.left: parent.left; anchors.leftMargin: 17
                anchors.verticalCenter: parent.verticalCenter
                spacing: 13
                Text {
                    text: "↗"
                    color: window.page === "links" ? "#F0C777" : "#C3C0BB"
                    font.pixelSize: 22
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Deck Links"
                    color: window.page === "links" ? "#FFF1DC" : "#CCD5E3"
                    font.family: "Segoe UI"
                    font.pixelSize: 14
                    font.bold: window.page === "links"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea {
                id: linksHover
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: window.toLinks()
            }
        }

        Rectangle {
            id: navDevice
            x: 12; y: 234
            width: parent.width - 24
            height: 50
            radius: 10
            color: window.page === "device" ? "#25232A" :
                   deviceHover.containsMouse ? "#202938" : "transparent"
            border.color: window.page === "device" ? "#6B513A" : "transparent"
            border.width: 1
            Rectangle {
                x: 0; width: 3; height: parent.height
                radius: 2
                color: "#F2BD67"
                visible: window.page === "device"
            }
            Row {
                anchors.left: parent.left; anchors.leftMargin: 17
                anchors.verticalCenter: parent.verticalCenter
                spacing: 13
                Text {
                    text: "⇄"
                    color: window.page === "device" ? "#F0C777" : "#C3C0BB"
                    font.pixelSize: 22
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Device Sync"
                    color: window.page === "device" ? "#FFF1DC" : "#CCD5E3"
                    font.family: "Segoe UI"
                    font.pixelSize: 14
                    font.bold: window.page === "device"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            MouseArea {
                id: deviceHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: window.toDevice()
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 26
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 38
            height: 118; radius: 13
            color: "#171E2B"
            border.color: "#313D4C"
            Text {
                anchors.left: parent.left; anchors.leftMargin: 15
                anchors.top: parent.top; anchors.topMargin: 14
                text: "✧  THE COMMAND ZONE"
                color: "#D4AF6B"
                font.family: "Segoe UI"
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1
            }
            Text {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: 15; anchors.rightMargin: 13
                anchors.top: parent.top; anchors.topMargin: 39
                text: "Your decks, your rules.\nReady for the next game."
                color: "#B0BCCC"
                font.family: "Segoe UI"
                font.pixelSize: 12
                lineHeight: 1.35
                wrapMode: Text.WordWrap
            }
        }
    }

    Item {
        id: workspace
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: sidebar.right
        anchors.right: parent.right
        clip: true

        Item {
            anchors.fill: parent
            visible: window.page === "library"

            Flickable {
                id: libraryScroll
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: libraryContent.implicitHeight + 52
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { radius: 4; color: "#667385" }
                }

                Column {
                    id: libraryContent
                    x: 31
                    y: 29
                    width: libraryScroll.width - 66
                    spacing: 24

                    Rectangle {
                        width: parent.width
                        height: 176
                        radius: 18
                        color: "#252332"
                        clip: true
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: "#262035" }
                            GradientStop { position: .5; color: "#4B3034" }
                            GradientStop { position: 1; color: "#182334" }
                        }

                        Canvas {
                            anchors.fill: parent
                            onPaint: {
                                var c=getContext("2d"), w=width, h=height
                                c.clearRect(0,0,w,h)
                                var sun=c.createRadialGradient(w*.79,h*.28,5,w*.79,h*.28,h*.9)
                                sun.addColorStop(0,"rgba(248,177,101,.32)")
                                sun.addColorStop(1,"rgba(255,140,65,0)")
                                c.fillStyle=sun;c.fillRect(0,0,w,h)
                                c.strokeStyle="rgba(238,178,106,.27)"
                                c.lineWidth=1
                                for(var i=0;i<5;i++){
                                    c.beginPath();c.arc(w*.86,h*.36,57+i*28,Math.PI*.82,Math.PI*1.96);c.stroke()
                                }
                                c.fillStyle="rgba(11,19,31,.34)"
                                c.beginPath();c.moveTo(w*.53,h);c.lineTo(w*.67,h*.50)
                                c.lineTo(w*.75,h*.74);c.lineTo(w*.86,h*.29)
                                c.lineTo(w,h*.65);c.lineTo(w,h);c.fill()
                                c.fillStyle="rgba(9,15,25,.53)"
                                c.beginPath();c.moveTo(w*.68,h);c.lineTo(w*.80,h*.77)
                                c.lineTo(w*.87,h*.87);c.lineTo(w*.96,h*.63)
                                c.lineTo(w,h*.76);c.lineTo(w,h);c.fill()
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: "transparent"
                            border.color: "#615049"
                            border.width: 1
                        }
                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 29
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10
                            Text {
                                text: "BUILD YOUR LEGACY"
                                color: "#F7D08A"
                                font.family: "Segoe UI"
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 3
                            }
                            Text {
                                text: "Every deck has a story."
                                color: "#FFF1DE"
                                font.family: "Georgia"
                                font.pixelSize: 31
                                font.bold: true
                            }
                            Text {
                                text: "Give your commanders a home. Make every counter count."
                                color: "#D4D1D6"
                                font.family: "Segoe UI"
                                font.pixelSize: 13
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 42
                        spacing: 12
                        Text {
                            text: "My Decks"
                            color: "#F9EEE0"
                            font.family: "Georgia"
                            font.pixelSize: 29
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            width: 75; height: 29; radius: 15
                            color: "#282318"; border.color: "#8C6837"
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.centerIn: parent
                                text: deckStore.count + " decks"
                                color: "#EBC882"
                                font.family: "Segoe UI"
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 45
                        spacing: 14

                        Rectangle {
                            id: searchBox
                            width: Math.max(240, parent.width - 333)
                            height: 45
                            radius: 11
                            color: "#151D28"
                            border.color: searchField.activeFocus ? "#C7A269" : "#384253"
                            border.width: 1
                            Text {
                                anchors.left: parent.left; anchors.leftMargin: 17
                                anchors.verticalCenter: parent.verticalCenter
                                text: "⌕"
                                font.pixelSize: 26
                                color: "#9FAEC3"
                            }
                            TextField {
                                id: searchField
                                anchors.fill: parent
                                anchors.leftMargin: 47
                                anchors.rightMargin: 10
                                placeholderText: "Search decks or commanders..."
                                placeholderTextColor: "#78879B"
                                color: "#F4F1E9"
                                font.family: "Segoe UI"
                                font.pixelSize: 13
                                background: Item {}
                                selectByMouse: true
                            }
                        }

                        Rectangle {
                            id: sortBox
                            width: 118; height: 45; radius: 11
                            color: "#151D28"
                            border.color: "#384253"
                            property bool checked: sortByName.checked
                            Text {
                                anchors.centerIn: parent
                                text: sortByName.checked ? "Name  A–Z" : "Newest first"
                                color: "#C8D2DF"
                                font.family: "Segoe UI"
                                font.pixelSize: 12
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: sortByName.checked = !sortByName.checked
                            }
                        }
                        QtObject { id: sortByName; property bool checked: false }

                        Rectangle {
                            id: createButton
                            width: 182; height: 45; radius: 11
                            gradient: Gradient {
                                GradientStop { position: 0; color: "#E8BC71" }
                                GradientStop { position: 1; color: "#B77D35" }
                            }
                            border.color: "#FFE19C"
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "+  New Deck"
                                color: "#22180F"
                                font.family: "Segoe UI"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.openEditor("")
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: deckStore.count === 0 ? 350 : deckGrid.implicitHeight + 10

                        Grid {
                            id: deckGrid
                            width: parent.width
                            spacing: 19
                            columns: Math.max(1, Math.floor((width + spacing) / 295))
                            property real cardWidth: (width - (columns - 1) * spacing) / columns

                            Repeater {
                                model: window.filteredDecks()
                                DeckCard {
                                    required property var modelData
                                    width: deckGrid.cardWidth
                                    height: 351
                                    profile: modelData
                                    onActivated: window.openEditor(modelData.id)
                                }
                            }
                        }

                        Column {
                            visible: deckStore.count === 0
                            anchors.centerIn: parent
                            spacing: 17
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "✦"
                                color: "#C79A55"
                                font.pixelSize: 56
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Your command zone awaits"
                                color: "#F5E8D7"
                                font.family: "Georgia"
                                font.pixelSize: 27
                                font.bold: true
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Create a deck, add your commander artwork, and choose its trackers."
                                color: "#95A1B3"
                                font.family: "Segoe UI"
                                font.pixelSize: 13
                            }
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 170; height: 42; radius: 11
                                color: "#CFA35B"
                                Text {
                                    anchors.centerIn: parent
                                    text: "Create first deck"
                                    color: "#21170D"
                                    font.bold: true
                                    font.pixelSize: 13
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: window.openEditor("")
                                }
                            }
                        }

                        Text {
                            visible: deckStore.count > 0 && window.filteredDecks().length === 0
                            anchors.centerIn: parent
                            text: "No decks match your search."
                            color: "#A7B4C7"
                            font.pixelSize: 16
                        }
                    }
                }
            }
        }

        Loader {
            id: linksLoader
            objectName: "linksLoader"
            anchors.fill: parent
            active: window.page === "links"
            sourceComponent: DeckLinks {
                libraryRevision: window.revision
                onEditRequested: function(deckId) {
                    window.openEditor(deckId)
                }
            }
        }

        Loader {
            id: deviceLoader
            objectName: "deviceLoader"
            anchors.fill: parent
            active: window.page === "device"
            sourceComponent: DeviceSyncPage {
                libraryRevision: window.revision
            }
        }

        Loader {
            id: editorLoader
            objectName: "editorLoader"
            anchors.fill: parent
            active: window.page === "editor"
            sourceComponent: DeckEditor {
                onBack: window.toLibrary()
                onSaved: function(id) {
                    window.showToast("Deck saved")
                    window.toLibrary()
                }
                onDeleted: {
                    window.showToast("Deck removed")
                    window.toLibrary()
                }
            }
            onLoaded: item.open(window.selectedDeck)
        }
    }

    Rectangle {
        id: toast
        visible: toastMessage.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        width: Math.min(430, toastText.implicitWidth + 48)
        height: 48
        radius: 12
        color: "#263128"
        border.color: "#76946E"
        z: 1000
        Text {
            id: toastText
            anchors.centerIn: parent
            text: window.toastMessage
            color: "#E9F1E1"
            font.family: "Segoe UI"
            font.pixelSize: 13
        }
    }
}
