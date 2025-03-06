import QtQuick

Image {
    id: background
    anchors.centerIn: parent
    source: "darklogin.png"

    Rectangle {
        anchors.fill: parent
        color: "#44000000"
    }

    Rectangle {
        id: groove
        width: 360
        height: 12
        anchors.centerIn: parent
        color: "#313131"
        radius: 6

        Rectangle {
            id: block
            height: 8
            width: 48
            radius: 4
            anchors.verticalCenter: parent.verticalCenter
            color: "#dcdcdc"

            SequentialAnimation on x {
                id: anim
                loops: Animation.Infinite

                NumberAnimation  {
                    from: 0
                    to: groove.width - block.width
                    duration: 1100
                    easing.type: Easing.OutQuad
                }
                NumberAnimation  {
                    from: groove.width - block.width
                    to: 0
                    duration: 1100
                    easing.type: Easing.OutQuad
                }
            }
        }
    }
}
