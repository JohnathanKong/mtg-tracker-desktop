import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: linksPage
    property int libraryRevision: 0
    property var profiles: {
        var changed = libraryRevision
        return deckStore.allDecks()
    }
    signal editRequested(string deckId)

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 90
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle { radius: 4; color: "#667385" }
        }

        Column {
            id: contentColumn
            x: 34
            y: 31
            width: parent.width - 68
            spacing: 24

            Rectangle {
                width: parent.width
                height: 157
                radius: 16
                clip: true
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#272033" }
                    GradientStop { position: 0.50; color: "#3D3037" }
                    GradientStop { position: 1; color: "#132638" }
                }
                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var c = getContext("2d"), w = width, h = height
                        c.clearRect(0,0,w,h)
                        c.strokeStyle="rgba(234,192,115,.20)";c.lineWidth=2
                        for(var i=0;i<5;i++){
                            c.beginPath()
                            c.arc(w*.86,h*.45,18+i*27,Math.PI*.85,Math.PI*1.99)
                            c.stroke()
                        }
                        c.fillStyle="rgba(7,14,27,.36)"
                        c.beginPath();c.moveTo(w*.57,h);c.lineTo(w*.76,h*.39)
                        c.lineTo(w*.88,h*.77);c.lineTo(w,h*.48)
                        c.lineTo(w,h);c.fill()
                    }
                }
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 29
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 9
                    Text {
                        text: "YOUR DECK COLLECTION"
                        color: "#E8C27B"
                        font.family: "Segoe UI"
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2.5
                    }
                    Text {
                        text: "Deck List Links"
                        color: "#FFF1DD"
                        font.family: "Georgia"
                        font.pixelSize: 32
                        font.bold: true
                    }
                    Text {
                        text: "Keep every deck list a single click away."
                        color: "#C9D0DC"
                        font.family: "Segoe UI"
                        font.pixelSize: 13
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    radius: parent.radius
                    border.color: "#6A5148"
                }
            }

            Row {
                width: parent.width
                height: 36
                spacing: 13
                Text {
                    text: "Your Links"
                    color: "#FAF1E3"
                    font.family: "Georgia"
                    font.pixelSize: 25
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    radius: 13; height: 26; width: 98
                    color: "#2B271F"; border.color: "#725B37"
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: profiles.filter(function(p) {return !!p.deckUrl}).length + " with links"
                        color: "#EAC782"
                        font.family: "Segoe UI"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }

            Text {
                visible: profiles.length === 0
                text: "No decks created yet. Add a deck to save a deck list link."
                color: "#AAB6C8"
                font.pixelSize: 15
            }

            Repeater {
                model: linksPage.profiles
                Rectangle {
                    required property var modelData
                    property var profile: modelData
                    width: contentColumn.width
                    height: 119
                    radius: 13
                    color: "#151D29"
                    border.color: "#364253"
                    border.width: 1

                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 17
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        height: 88
                        spacing: 18

                        Rectangle {
                            width: 70; height: 84; radius: 9
                            color: "#3D3040"
                            clip: true
                            border.color: "#8B6A49"
                            Image {
                                anchors.fill: parent
                                source: profile.artworkUrl || ""
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "✦"
                                color: "#DCB66A"
                                font.pixelSize: 28
                                visible: !profile.artworkUrl
                            }
                        }

                        Column {
                            width: Math.max(200,parent.width - 70 - 18 - 238 - 18)
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5
                            Text {
                                width: parent.width
                                text: profile.name
                                color: "#FCF0DC"
                                font.family: "Georgia"
                                font.pixelSize: 19
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: profile.commander || "No commander set"
                                color: "#A5B2C3"
                                font.family: "Segoe UI"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: profile.deckUrl || "No deck list URL added"
                                color: profile.deckUrl ? "#E3BE82" : "#78889E"
                                font.family: "Segoe UI"
                                font.pixelSize: 12
                                maximumLineCount: 2
                                wrapMode: Text.WrapAnywhere
                            }
                        }

                        Rectangle {
                            id: openButton
                            width: 122; height: 41; radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: openArea.containsMouse ? "#EAC67D" : "#C69D59"
                            opacity: profile.deckUrl ? 1 : .36
                            Text {
                                anchors.centerIn: parent
                                text: "↗  Open Link"
                                color: "#1B1711"
                                font.family: "Segoe UI"
                                font.pixelSize: 13
                                font.bold: true
                            }
                            MouseArea {
                                id: openArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !!profile.deckUrl
                                cursorShape: Qt.PointingHandCursor
                                onClicked: deckStore.openDeckUrl(profile.deckUrl)
                            }
                        }

                        Rectangle {
                            width: 98; height: 41; radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: editArea.containsMouse ? "#283748" : "#202A37"
                            border.color: "#566277"
                            Text {
                                anchors.centerIn: parent
                                text: profile.deckUrl ? "Edit Deck" : "+ Add Link"
                                color: "#D9E0EA"
                                font.family: "Segoe UI"
                                font.pixelSize: 12
                            }
                            MouseArea {
                                id: editArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: linksPage.editRequested(profile.id)
                            }
                        }
                    }
                }
            }

            Text {
                text: "Your deck lists open in your default browser. Nothing is uploaded or synced by this app."
                color: "#7D8CA1"
                font.family: "Segoe UI"
                font.pixelSize: 11
            }
        }
    }
}
