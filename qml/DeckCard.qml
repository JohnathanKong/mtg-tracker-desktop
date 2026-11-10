import QtQuick 2.15

Item {
    id: card
    property var profile: ({})
    property color baseColor: {
        var c = profile.colors || []
        if (c.indexOf("R") >= 0) return "#AF4C43"
        if (c.indexOf("G") >= 0) return "#3B9B7C"
        if (c.indexOf("U") >= 0) return "#478DCB"
        if (c.indexOf("B") >= 0) return "#9462AA"
        if (c.indexOf("W") >= 0) return "#D5B96D"
        return "#D6AD66"
    }
    property bool hovering: hit.containsMouse
    signal activated()

    width: 272
    height: 366
    scale: hovering ? 1.018 : 1
    Behavior on scale { NumberAnimation { duration: 145; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: "#141B27"
        border.width: hovering ? 2 : 1
        border.color: hovering ? "#E3BE73" : "#354052"
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    Item {
        anchors.fill: parent
        anchors.margins: 2
        clip: true

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: card.baseColor }
                GradientStop { position: 0.46; color: "#273146" }
                GradientStop { position: 1; color: "#0C111C" }
            }
        }

        // Atmospheric illustration shown until the user imports their own artwork.
        Canvas {
            id: placeholder
            anchors.fill: parent
            visible: !card.profile.artworkUrl
            onPaint: {
                var p = getContext("2d"), w = width, h = height
                p.clearRect(0, 0, w, h)
                var sky = p.createLinearGradient(0, 0, w, h)
                sky.addColorStop(0, "#4B4555")
                sky.addColorStop(0.35, card.baseColor.toString())
                sky.addColorStop(0.72, "#1C283B")
                sky.addColorStop(1, "#080F19")
                p.fillStyle = sky; p.fillRect(0, 0, w, h)
                var glow = p.createRadialGradient(w*0.67,h*0.25,4,w*0.67,h*0.25,w*0.7)
                glow.addColorStop(0,"rgba(255,211,140,0.62)")
                glow.addColorStop(0.3,"rgba(232,148,98,0.24)")
                glow.addColorStop(1,"rgba(11,16,28,0)")
                p.fillStyle=glow; p.fillRect(0,0,w,h)
                p.fillStyle="rgba(12,22,35,.65)"
                p.beginPath(); p.moveTo(0,h*.56); p.lineTo(w*.18,h*.38);p.lineTo(w*.33,h*.49)
                p.lineTo(w*.56,h*.28);p.lineTo(w*.74,h*.44);p.lineTo(w,h*.30);p.lineTo(w,h);p.lineTo(0,h);p.fill()
                p.fillStyle="rgba(8,14,24,.90)"
                p.beginPath();p.moveTo(0,h*.76);p.lineTo(w*.23,h*.63);p.lineTo(w*.37,h*.71)
                p.lineTo(w*.7,h*.48);p.lineTo(w,h*.69);p.lineTo(w,h);p.lineTo(0,h);p.fill()
                p.strokeStyle="rgba(255,214,151,.40)"
                for(var i=0;i<13;i++) {
                    var x=(i*83+41)%w, y=(i*47+21)%(h*.63)
                    p.fillStyle="rgba(255,231,187,.55)";p.fillRect(x,y,1.4,1.4)
                }
            }
        }

        Image {
            anchors.fill: parent
            source: card.profile.artworkUrl || ""
            visible: status === Image.Ready
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 0.43; color: "#0B101400" }
                GradientStop { position: 0.65; color: "#D10C121B" }
                GradientStop { position: 1.0; color: "#FC0B1019" }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 4
            color: card.baseColor
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 17
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 112
            spacing: 5
            Repeater {
                model: (card.profile.colors && card.profile.colors.length) ? card.profile.colors : []
                Rectangle {
                    required property string modelData
                    width: 23; height: 23
                    radius: 12
                    border.color: "#99FFFFFF"
                    border.width: 1
                    color: {
                        if (modelData === "W") return "#EBD9AE"
                        if (modelData === "U") return "#3986C3"
                        if (modelData === "B") return "#75727F"
                        if (modelData === "R") return "#D14C40"
                        return "#38936B"
                    }
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: modelData === "W" ? "#342E25" : "white"
                        font.family: "Segoe UI"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 18
            anchors.rightMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 19
            spacing: 6
            Text {
                width: parent.width
                text: card.profile.name || "Untitled deck"
                color: "#FFF7ED"
                font.family: "Georgia"
                font.bold: true
                font.pixelSize: 23
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: card.profile.commander || "Commander not set"
                color: "#C1C9D8"
                font.family: "Segoe UI"
                font.pixelSize: 13
                elide: Text.ElideRight
            }
            Rectangle { width: parent.width; height: 1; color: "#40505B6E" }
            Row {
                spacing: 7
                Text { text: "✦"; color: "#F3C66F"; font.pixelSize: 14 }
                Text {
                    text: (card.profile.trackerCount || 0) + " active trackers"
                    color: "#E7C886"
                    font.family: "Segoe UI"
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }
    }
    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.activated()
    }
}
