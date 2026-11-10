import QtQuick 2.15

Item {
    id: chip
    property string label: ""
    property string symbol: "✦"
    property bool checked: false
    signal toggled()

    implicitWidth: Math.max(128, labelText.implicitWidth + 74)
    implicitHeight: 48
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: 11
        color: chip.checked ? "#302C26" : hover.containsMouse ? "#202936" : "#151D28"
        border.color: chip.checked ? "#D5A956" : hover.containsMouse ? "#53617A" : "#2B3443"
        border.width: chip.checked ? 1.4 : 1
        Behavior on color { ColorAnimation { duration: 130 } }
        Behavior on border.color { ColorAnimation { duration: 130 } }
    }

    Text {
        id: glyph
        anchors.left: parent.left
        anchors.leftMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        text: chip.symbol
        color: chip.checked ? "#F8CC70" : "#8997AB"
        font.pixelSize: 19
    }

    Text {
        id: labelText
        anchors.left: glyph.right
        anchors.leftMargin: 10
        anchors.right: status.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: chip.label
        color: chip.checked ? "#FFF7E7" : "#CAD3DF"
        elide: Text.ElideRight
        font.family: "Segoe UI"
        font.pixelSize: 13
        font.weight: chip.checked ? Font.DemiBold : Font.Normal
    }

    Rectangle {
        id: status
        width: 19; height: 19
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        radius: 5
        color: chip.checked ? "#D8AC5D" : "transparent"
        border.color: chip.checked ? "#F2CA80" : "#5A6678"
        border.width: 1
        Text {
            anchors.centerIn: parent
            text: "✓"
            color: "#18140D"
            font.bold: true
            font.pixelSize: 13
            visible: chip.checked
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.toggled()
    }
}
