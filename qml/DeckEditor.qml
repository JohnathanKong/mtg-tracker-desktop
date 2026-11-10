import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

Item {
    id: editor
    signal back()
    signal saved(string id)
    signal deleted()

    property string profileId: ""
    property string artworkPath: ""
    property string artworkUrl: ""
    property var trackers: []
    property var colors: []
    property bool creating: profileId.length === 0

    property var basicTrackers: [
        { id: "life", label: "Life total", icon: "♥" },
        { id: "poison", label: "Poison", icon: "☠" },
        { id: "rad", label: "Radiation", icon: "☢" },
        { id: "commander_damage", label: "Commander damage", icon: "⚔" },
        { id: "commander_casts", label: "Casts / tax", icon: "♜" },
        { id: "commander_deaths", label: "Commander deaths", icon: "↻" }
    ]
    property var mechanicTrackers: [
        { id: "experience", label: "Experience", icon: "✧" },
        { id: "energy", label: "Energy", icon: "ϟ" },
        { id: "storm", label: "Storm count", icon: "◉" },
        { id: "tickets", label: "Tickets", icon: "▱" },
        { id: "speed", label: "Speed", icon: "◴" },
        { id: "ring", label: "Ring temptation", icon: "◈" },
        { id: "dungeon", label: "Dungeon progress", icon: "⌂" }
    ]
    property var statusTrackers: [
        { id: "monarch", label: "Monarch", icon: "♛" },
        { id: "initiative", label: "Initiative", icon: "⚑" },
        { id: "citys_blessing", label: "City's blessing", icon: "✺" },
        { id: "day_night", label: "Day / night", icon: "☾" },
        { id: "emblems", label: "Emblems", icon: "⬡" }
    ]
    property var extraTrackers: [
        { id: "mana_pool", label: "Mana pool", icon: "✦" },
        { id: "turn", label: "Turn number", icon: "⧖" },
        { id: "custom_1", label: "Custom 1", icon: "＋" },
        { id: "custom_2", label: "Custom 2", icon: "＋" }
    ]
    property var groups: [
        { title: "Always Track", description: "Useful in almost every Commander game.", symbol: "✦", items: basicTrackers },
        { title: "Deck Mechanics", description: "Include only what your deck actually uses.", symbol: "ϟ", items: mechanicTrackers },
        { title: "Game States", description: "Situational effects and player statuses.", symbol: "♛", items: statusTrackers },
        { title: "Extras", description: "Additional counters and custom slots.", symbol: "⊕", items: extraTrackers }
    ]

    function open(id) {
        var d = id ? deckStore.deck(id) : {}
        profileId = d.id || ""
        deckName.text = d.name || ""
        commanderName.text = d.commander || ""
        artworkPath = d.artwork || ""
        artworkUrl = d.artworkUrl || ""
        trackers = d.id ? (d.trackers || []).slice() :
            ["life","poison","rad","commander_damage","commander_casts","commander_deaths"]
        colors = (d.colors || []).slice()
        pageScroll.contentY = 0
        deckName.forceActiveFocus()
    }

    function toggleTracker(id) {
        var next = trackers.slice()
        var index = next.indexOf(id)
        if (index < 0) next.push(id)
        else next.splice(index, 1)
        trackers = next
    }

    function toggleColor(id) {
        var next = colors.slice()
        var index = next.indexOf(id)
        if (index < 0) next.push(id)
        else next.splice(index, 1)
        colors = next
    }

    function saveDeck() {
        if (!deckName.text.trim()) {
            validationMessage.text = "A deck name is required."
            return
        }
        validationMessage.text = ""
        var id = deckStore.saveDeck({
            id: profileId,
            name: deckName.text.trim(),
            commander: commanderName.text.trim(),
            artwork: artworkPath,
            trackers: trackers,
            colors: colors
        })
        if (id) saved(id)
    }

    function accentColor() {
        if (colors.indexOf("R") >= 0) return "#B66D50"
        if (colors.indexOf("G") >= 0) return "#408F78"
        if (colors.indexOf("U") >= 0) return "#4F82B4"
        if (colors.indexOf("B") >= 0) return "#785A9B"
        if (colors.indexOf("W") >= 0) return "#CEB16D"
        return "#C79656"
    }

    FileDialog {
        id: artworkDialog
        title: "Choose commander or deck artwork"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.webp *.bmp *.gif)"]
        onAccepted: {
            var path = deckStore.importArtwork(selectedFile)
            if (path) {
                editor.artworkPath = path
                editor.artworkUrl = selectedFile.toString()
            }
        }
    }

    Flickable {
        id: pageScroll
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: editorColumn.implicitHeight + 65
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle { radius: 5; color: "#56677A" }
        }

        Column {
            id: editorColumn
            x: 32
            y: 27
            width: pageScroll.width - 66
            spacing: 24

            Row {
                width: parent.width
                height: 34
                Text {
                    text: "‹  BACK TO DECKS"
                    color: backArea.containsMouse ? "#FFE2AD" : "#BFC8D3"
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1.4
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        id: backArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: editor.back()
                    }
                }
            }

            Rectangle {
                id: hero
                width: parent.width
                height: 190
                radius: 16
                color: "#282333"
                clip: true
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#2A2330" }
                    GradientStop { position: .52; color: editor.accentColor() }
                    GradientStop { position: 1; color: "#1B2635" }
                }

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var c = getContext("2d"), w=width, h=height
                        c.strokeStyle="rgba(255,231,188,.28)"
                        c.lineWidth=1.2
                        for(var i=0;i<5;i++) {
                            c.beginPath();c.arc(w*.87,h*.42,42+i*28,Math.PI*.81,Math.PI*1.95);c.stroke()
                        }
                        c.fillStyle="rgba(12,18,28,.44)"
                        c.beginPath();c.moveTo(w*.47,h);c.lineTo(w*.68,h*.46)
                        c.lineTo(w*.73,h*.62);c.lineTo(w*.91,h*.26)
                        c.lineTo(w,h*.67);c.lineTo(w,h);c.fill()
                    }
                }

                Image {
                    anchors.fill: parent
                    source: editor.artworkUrl
                    visible: status === Image.Ready
                    fillMode: Image.PreserveAspectCrop
                    opacity: .62
                    asynchronous: true
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "#F00C121D" }
                        GradientStop { position: .58; color: "#660C121D" }
                        GradientStop { position: 1; color: "#100C121D" }
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 31
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 9
                    Text {
                        text: editor.creating ? "A NEW LEGEND BEGINS" : "YOUR COMMAND ZONE"
                        color: "#F1C880"
                        font.family: "Segoe UI"
                        font.pixelSize: 11
                        font.letterSpacing: 2.4
                        font.bold: true
                    }
                    Text {
                        width: Math.min(730, hero.width - 65)
                        text: deckName.text.trim() || "Name your next legend"
                        color: "#FFF5E7"
                        font.family: "Georgia"
                        font.bold: true
                        font.pixelSize: 33
                        elide: Text.ElideRight
                    }
                    Text {
                        text: editor.creating ? "Create a commander deck profile" :
                              (commanderName.text.trim() || "Choose a commander")
                        color: "#E3D9CB"
                        font.family: "Segoe UI"
                        font.pixelSize: 14
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: "#786452"
                }
            }

            Row {
                width: parent.width
                spacing: 23

                Column {
                    id: artColumn
                    width: Math.min(268, editorColumn.width * .31)
                    spacing: 12

                    Rectangle {
                        id: artFrame
                        width: parent.width
                        height: 298
                        radius: 14
                        color: "#162131"
                        border.color: "#A57B4A"
                        border.width: 1
                        clip: true

                        Canvas {
                            anchors.fill: parent
                            visible: !editor.artworkUrl
                            onPaint: {
                                var c=getContext("2d"),w=width,h=height
                                var gr=c.createLinearGradient(0,0,w,h)
                                gr.addColorStop(0,"#463747")
                                gr.addColorStop(.42,"#675041")
                                gr.addColorStop(1,"#141B29")
                                c.fillStyle=gr;c.fillRect(0,0,w,h)
                                c.fillStyle="rgba(249,195,114,.18)"
                                c.beginPath();c.arc(w*.6,h*.33,85,0,Math.PI*2);c.fill()
                                c.fillStyle="rgba(10,17,29,.65)"
                                c.beginPath();c.moveTo(0,h*.83);c.lineTo(w*.31,h*.57)
                                c.lineTo(w*.51,h*.73);c.lineTo(w*.74,h*.48)
                                c.lineTo(w,h*.65);c.lineTo(w,h);c.lineTo(0,h);c.fill()
                            }
                        }

                        Image {
                            anchors.fill: parent
                            source: editor.artworkUrl
                            visible: status === Image.Ready
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            visible: !editor.artworkUrl
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "✧"
                                color: "#E4B974"
                                font.pixelSize: 52
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "YOUR ARTWORK"
                                color: "#F4DBAF"
                                font.family: "Segoe UI"
                                font.pixelSize: 12
                                font.bold: true
                                font.letterSpacing: 2
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "PNG  •  JPG  •  WEBP"
                                color: "#B2A7AA"
                                font.pixelSize: 10
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 43; radius: 10
                        color: imageHover.containsMouse ? "#293648" : "#1C2735"
                        border.color: "#536075"
                        Text {
                            anchors.centerIn: parent
                            text: "▧   " + (editor.artworkPath ? "Change artwork" : "Import artwork")
                            color: "#F1E8DA"
                            font.family: "Segoe UI"
                            font.pixelSize: 13
                            font.bold: true
                        }
                        MouseArea {
                            id: imageHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: artworkDialog.open()
                        }
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "Imported images stay on this computer."
                        color: "#8998AA"
                        font.family: "Segoe UI"
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Column {
                    width: editorColumn.width - artColumn.width - 23
                    spacing: 20

                    Text {
                        text: "DECK DETAILS"
                        font.family: "Segoe UI"
                        font.pixelSize: 11
                        color: "#DBB16B"
                        font.bold: true
                        font.letterSpacing: 2
                    }

                    Column {
                        width: parent.width
                        spacing: 7
                        Text {
                            text: "Deck name"
                            color: "#C7D1DD"
                            font.family: "Segoe UI"
                            font.pixelSize: 13
                        }
                        TextField {
                            id: deckName
                            width: parent.width
                            height: 48
                            font.family: "Segoe UI"
                            font.pixelSize: 15
                            color: "#FFF7E8"
                            placeholderText: "e.g. Krenko Goblins"
                            placeholderTextColor: "#71839A"
                            selectByMouse: true
                            background: Rectangle {
                                radius: 10
                                color: "#151D29"
                                border.width: 1
                                border.color: deckName.activeFocus ? "#CCA368" : "#394657"
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 7
                        Text {
                            text: "Commander name"
                            color: "#C7D1DD"
                            font.family: "Segoe UI"
                            font.pixelSize: 13
                        }
                        TextField {
                            id: commanderName
                            width: parent.width
                            height: 48
                            font.family: "Segoe UI"
                            font.pixelSize: 15
                            color: "#FFF7E8"
                            placeholderText: "e.g. Krenko, Mob Boss"
                            placeholderTextColor: "#71839A"
                            selectByMouse: true
                            background: Rectangle {
                                radius: 10
                                color: "#151D29"
                                border.width: 1
                                border.color: commanderName.activeFocus ? "#CCA368" : "#394657"
                            }
                        }
                    }

                    Column {
                        spacing: 10
                        Text {
                            text: "Color identity  ·  optional"
                            color: "#C7D1DD"
                            font.family: "Segoe UI"
                            font.pixelSize: 13
                        }
                        Row {
                            spacing: 12
                            Repeater {
                                model: [
                                    { code:"W", color:"#E9D5A7", ink:"#312C25", label:"White" },
                                    { code:"U", color:"#3B90CC", ink:"#FFFFFF", label:"Blue" },
                                    { code:"B", color:"#77717D", ink:"#FFFFFF", label:"Black" },
                                    { code:"R", color:"#D65245", ink:"#FFFFFF", label:"Red" },
                                    { code:"G", color:"#39946C", ink:"#FFFFFF", label:"Green" }
                                ]
                                Rectangle {
                                    required property var modelData
                                    property bool chosen: editor.colors.indexOf(modelData.code) !== -1
                                    width: 42; height: 42
                                    radius: 21
                                    color: modelData.color
                                    opacity: chosen ? 1 : .58
                                    border.color: chosen ? "#FFF4D8" : "#525864"
                                    border.width: chosen ? 3 : 1
                                    scale: chosen ? 1.05 : 1
                                    Behavior on scale { NumberAnimation { duration: 110 } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.code
                                        color: modelData.ink
                                        font.family: "Segoe UI"
                                        font.pixelSize: 17
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: editor.toggleColor(modelData.code)
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 58
                        radius: 10
                        color: "#171F2A"
                        border.color: "#324052"
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 14
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "✦"
                                color: "#EDBF71"
                                font.pixelSize: 25
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                Text {
                                    text: editor.trackers.length + " active trackers"
                                    color: "#F2E7D3"
                                    font.family: "Segoe UI"
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                                Text {
                                    text: "Custom to this deck — not tied to the commander card."
                                    color: "#9BA8BA"
                                    font.family: "Segoe UI"
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 6
                Text {
                    text: "Counters & trackers"
                    color: "#FFF3E1"
                    font.family: "Georgia"
                    font.pixelSize: 28
                    font.bold: true
                }
                Text {
                    text: "Choose only the trackers this deck needs. Opponents can still give you poison or rad counters."
                    color: "#A4B0BF"
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                }
            }

            Repeater {
                model: editor.groups
                Rectangle {
                    required property var modelData
                    property var groupInfo: modelData
                    width: editorColumn.width
                    height: groupColumn.implicitHeight + 38
                    radius: 14
                    color: "#121A25"
                    border.color: "#303C4C"
                    border.width: 1

                    Column {
                        id: groupColumn
                        x: 20
                        y: 19
                        width: parent.width - 40
                        spacing: 15

                        Row {
                            spacing: 12
                            Text {
                                text: groupInfo.symbol
                                color: "#E6B96D"
                                font.pixelSize: 23
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: groupInfo.title
                                color: "#F5E9D8"
                                font.family: "Segoe UI"
                                font.pixelSize: 17
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "  " + groupInfo.description
                                color: "#8E9BAD"
                                font.family: "Segoe UI"
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Flow {
                            width: parent.width
                            spacing: 10
                            Repeater {
                                model: groupInfo.items
                                CounterChip {
                                    required property var modelData
                                    label: modelData.label
                                    symbol: modelData.icon
                                    checked: editor.trackers.indexOf(modelData.id) !== -1
                                    onToggled: editor.toggleTracker(modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#374355"
            }

            Row {
                width: parent.width
                height: 51
                spacing: 13

                Rectangle {
                    visible: !editor.creating
                    width: 139; height: 48; radius: 10
                    color: deleteHover.containsMouse ? "#381D26" : "#211821"
                    border.color: "#A64C50"
                    Text {
                        anchors.centerIn: parent
                        text: "⌫  Delete deck"
                        color: "#FF8D85"
                        font.family: "Segoe UI"
                        font.pixelSize: 13
                        font.bold: true
                    }
                    MouseArea {
                        id: deleteHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: confirmDelete.open()
                    }
                }

                Item { width: Math.max(10, editorColumn.width - (editor.creating ? 357 : 509)); height: 1 }

                Rectangle {
                    width: 154; height: 48; radius: 10
                    color: discardHover.containsMouse ? "#2D3643" : "#202835"
                    border.color: "#48576B"
                    Text {
                        anchors.centerIn: parent
                        text: "Discard changes"
                        color: "#D3D8E0"
                        font.family: "Segoe UI"
                        font.pixelSize: 13
                    }
                    MouseArea {
                        id: discardHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: editor.back()
                    }
                }

                Rectangle {
                    width: 180; height: 48; radius: 10
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#F4CC7B" }
                        GradientStop { position: 1; color: "#B9873B" }
                    }
                    border.color: "#FFE3A3"
                    Text {
                        anchors.centerIn: parent
                        text: editor.creating ? "✦  Create Deck" : "✓  Save Changes"
                        color: "#21170D"
                        font.family: "Segoe UI"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: editor.saveDeck()
                    }
                }
            }

            Text {
                id: validationMessage
                text: ""
                color: "#F28A84"
                font.family: "Segoe UI"
                font.pixelSize: 12
                visible: text.length > 0
            }
        }
    }

    Popup {
        id: confirmDelete
        modal: true
        focus: true
        width: 395
        height: 205
        x: Math.round((editor.width-width)/2)
        y: Math.round((editor.height-height)/2)
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            color: "#18212F"
            radius: 16
            border.color: "#8D534C"
            border.width: 1
        }

        contentItem: Column {
            spacing: 17
            Text {
                text: "Delete this deck?"
                color: "#F8EDDB"
                font.family: "Georgia"
                font.pixelSize: 22
                font.bold: true
            }
            Text {
                text: "This removes the deck profile. Imported artwork files are kept."
                width: parent.width
                wrapMode: Text.WordWrap
                color: "#B7C3CF"
                font.family: "Segoe UI"
                font.pixelSize: 13
            }
            Row {
                spacing: 14
                Button {
                    text: "Cancel"
                    onClicked: confirmDelete.close()
                }
                Button {
                    text: "Delete deck"
                    onClicked: {
                        if (deckStore.deleteDeck(editor.profileId)) {
                            confirmDelete.close()
                            editor.deleted()
                        }
                    }
                }
            }
        }
    }
}
