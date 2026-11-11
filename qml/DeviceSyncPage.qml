import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: page
    property int libraryRevision: 0
    property var profiles: {
        var revision = libraryRevision
        return deckStore.allDecks()
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: panel.implicitHeight + 84
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle { radius: 4; color: "#637187" }
        }

        Column {
            id: panel
            x: 32; y: 28
            width: parent.width - 67
            spacing: 23

            Rectangle {
                width: parent.width; height: 176
                radius: 17
                clip: true
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#1C2939" }
                    GradientStop { position: .49; color: "#344659" }
                    GradientStop { position: 1; color: "#302439" }
                }
                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var c = getContext("2d"),w=width,h=height
                        c.clearRect(0,0,w,h)
                        c.strokeStyle = "rgba(244,199,118,.28)"
                        c.lineWidth=2
                        for(var i=0;i<5;i++){
                            c.beginPath()
                            c.arc(w*.85,h*.55,26+i*26,Math.PI*1.05,Math.PI*1.95)
                            c.stroke()
                        }
                    }
                }
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 28
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 9
                    Text {
                        text: "YOUR DECKS. YOUR DEVICE."
                        color: "#F2C77E"
                        font.pixelSize: 11
                        font.bold: true
                        font.family: "Segoe UI"
                        font.letterSpacing: 2.5
                    }
                    Text {
                        text: "Device Synchronization"
                        color: "#FFF1DC"
                        font.family: "Georgia"
                        font.bold: true
                        font.pixelSize: 31
                    }
                    Text {
                        text: "One cable. Your full deck library ready for independent play."
                        color: "#D2DBE5"
                        font.family: "Segoe UI"
                        font.pixelSize: 13
                    }
                }
                Rectangle { anchors.fill: parent; color: "transparent"; border.color:"#536074"; radius:17 }
            }

            Row {
                width: parent.width; height: 42; spacing: 12
                Text {
                    text: "USB Connection"
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#F9EAD3"
                    font.family: "Georgia"
                    font.pixelSize: 26
                    font.bold: true
                }
                Rectangle {
                    width: 151; height: 28; radius: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color:"#1D2D30"; border.color:"#3E696B"
                    Text {
                        anchors.centerIn: parent
                        text: "ESP32-S3   •   USB"
                        color:"#91D5D2"; font.pixelSize:11; font.bold:true
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 239
                radius: 15
                color: "#131C28"
                border.color: "#344357"

                Column {
                    x: 22; y: 20
                    width: parent.width - 44
                    spacing: 13
                    Text {
                        text: "Select the ESP32-S3 serial port"
                        color: "#E8E5E0"
                        font.family: "Segoe UI"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    Row {
                        width: parent.width; height: 46
                        spacing: 13
                        ComboBox {
                            id: portPicker
                            editable: true
                            width: Math.max(220,parent.width - 135)
                            height: 46
                            model: deviceSync.ports
                            enabled: !deviceSync.busy
                            font.family: "Segoe UI"
                            font.pixelSize: 14
                            onModelChanged: {
                                if (count > 0 && editText.length === 0)
                                    currentIndex = 0
                            }
                            background: Rectangle {
                                radius: 10
                                color: "#1B2734"
                                border.color: portPicker.activeFocus ? "#D1A96A" : "#4B5C70"
                            }
                            contentItem: TextField {
                                text: portPicker.editText
                                placeholderText: "Choose or type COM port (COM3)"
                                color: "#F4E9DA"
                                placeholderTextColor: "#8192A6"
                                readOnly: !portPicker.editable
                                font: portPicker.font
                                verticalAlignment: Text.AlignVCenter
                                background: Item {}
                                onTextEdited: portPicker.editText = text
                            }
                        }
                        Rectangle {
                            width: 122; height: 46; radius: 10
                            color: refreshHover.containsMouse ? "#334152" : "#222F3D"
                            border.color: "#576780"
                            Text {
                                anchors.centerIn: parent
                                text: "↻  Refresh"
                                font.family: "Segoe UI"
                                font.pixelSize: 13
                                font.bold: true
                                color: "#E5E5E7"
                            }
                            MouseArea {
                                id: refreshHover
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !deviceSync.busy
                                cursorShape: Qt.PointingHandCursor
                                onClicked: deviceSync.refreshPorts()
                            }
                        }
                    }
                    Text {
                        text: "Choose the ESP32-S3 COM port. The device must have MTG receiver firmware."
                        color: "#9BAABD"
                        font.family: "Segoe UI"
                        font.pixelSize: 12
                    }

                    Rectangle { width: parent.width; height: 1; color: "#344153" }

                    Row {
                        width: parent.width; height: 52
                        spacing: 15
                        Rectangle {
                            width: 202; height: 50; radius: 10
                            color: deviceSync.busy ? "#6A5B46" :
                                   syncHover.containsMouse ? "#F0CD85" : "#CBA363"
                            border.color: "#F7D58B"
                            Text {
                                anchors.centerIn: parent
                                text: deviceSync.busy ? "Transferring..." : "⇧  Sync Deck Library"
                                color: "#241911"
                                font.family: "Segoe UI"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            MouseArea {
                                id: syncHover
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !deviceSync.busy
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var port = portPicker.editText.trim()
                                    if (!port) {
                                        pageHint.text = "Choose or enter a COM port first."
                                        return
                                    }
                                    pageHint.text = ""
                                    deviceSync.sync(port, page.profiles)
                                }
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5
                            Text {
                                text: page.profiles.length + " deck profiles"
                                color: "#F2DBAF"
                                font.family: "Segoe UI"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            Text {
                                text: "Names, colors, counters and custom tracker labels"
                                color: "#9BA9BC"
                                font.family: "Segoe UI"
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width; height: 113
                radius: 13
                color: "#141D29"
                border.color: "#354253"
                Column {
                    x: 20; y: 16; width: parent.width - 40; spacing: 12
                    Row {
                        width: parent.width
                        spacing: 10
                        Text {
                            text: deviceSync.busy ? "◌" :
                                  deviceSync.progress === 100 ? "✓" : "✦"
                            color: deviceSync.progress === 100 ? "#9BE2AC" : "#EFC57C"
                            font.pixelSize: 18
                        }
                        Text {
                            width: parent.width - 32
                            text: deviceSync.status
                            color: "#D6E1EE"
                            font.family: "Segoe UI"
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                        }
                    }
                    Rectangle {
                        width: parent.width; height: 8; radius: 4
                        color: "#293848"
                        Rectangle {
                            width: parent.width * deviceSync.progress / 100
                            height: parent.height; radius: 4
                            color: "#E6BB6E"
                            Behavior on width { NumberAnimation { duration: 100 } }
                        }
                    }
                    Text {
                        id: pageHint
                        text: ""
                        color: "#F0A19A"
                        font.pixelSize: 11
                        visible: text.length > 0
                    }
                }
            }

            Row {
                width: parent.width; height: 33; spacing: 13
                Text {
                    text: "Profiles to transfer"
                    color: "#F6E7D1"
                    font.family: "Georgia"
                    font.pixelSize: 23
                    font.bold: true
                }
                Text {
                    text: "All saved profiles will replace the device's existing deck library."
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#8EA0B6"
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                }
            }

            Flow {
                width: parent.width
                spacing: 13
                Repeater {
                    model: page.profiles
                    Rectangle {
                        required property var modelData
                        width: Math.min(390, Math.max(258, (panel.width - 28) / 2))
                        height: 81
                        radius: 12
                        color: "#161F2C"
                        border.color: "#354457"
                        Row {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12
                            Rectangle {
                                width: 44; height: 56; radius: 8
                                color: "#483C46"
                                clip: true
                                Image {
                                    anchors.fill: parent
                                    source: modelData.artworkUrl || ""
                                    fillMode: Image.PreserveAspectCrop
                                }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5
                                Text {
                                    width: 260
                                    text: modelData.name
                                    color: "#F9EBD6"
                                    font.family: "Georgia"
                                    font.pixelSize: 16
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: 260
                                    text: modelData.commander || "Commander not set"
                                    color: "#AAB7C6"
                                    font.family: "Segoe UI"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: (modelData.trackerCount || 0) + " trackers"
                                    color: "#E7BE7D"
                                    font.family: "Segoe UI"
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width; height: 112; radius: 13
                color: "#231F26"
                border.color: "#69553F"
                Column {
                    anchors.fill: parent
                    anchors.margins: 17
                    spacing: 8
                    Text {
                        text: "BEFORE YOU CONNECT"
                        color: "#F5C985"
                        font.family: "Segoe UI"
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.6
                    }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        text: "The Waveshare knob contains TWO processors. Flipping the USB-C plug changes which processor you reach. Use the ESP32-S3 port. Firmware must be flashed separately once; a deck sync will NEVER flash or update firmware."
                        color: "#C6CAD3"
                        font.family: "Segoe UI"
                        font.pixelSize: 12
                    }
                    Text {
                        text: "Artwork transfer, game-state updates, and on-device menus will be added later."
                        color: "#C5A675"
                        font.family: "Segoe UI"
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
