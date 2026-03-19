import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root

    property real padding: 6
    implicitWidth: mainLayout.implicitWidth + padding * 2
    implicitHeight: mainLayout.implicitHeight + padding * 2
    color: Appearance.colors.colLayer2
    radius: Appearance.rounding.normal

    function triggerSearch() {
        Wallhaven.query = searchField.text
        Wallhaven.search()
    }

    RowLayout {
        id: mainLayout
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: 6

        ToolbarTextField {
            id: searchField
            Layout.fillWidth: true
            implicitWidth: 160
            placeholderText: Translation.tr("Search wallhaven...")
            Keys.onReturnPressed: root.triggerSearch()
            Keys.onEnterPressed: root.triggerSearch()
        }

        IconToolbarButton {
            implicitWidth: height
            text: "search"
            onClicked: root.triggerSearch()
            StyledToolTip { text: Translation.tr("Search") }
        }

        IconToolbarButton {
            implicitWidth: height
            text: "casino"
            onClicked: {
                Wallhaven.query = searchField.text
                Wallhaven.random()
            }
            StyledToolTip { text: Translation.tr("Random wallpapers") }
        }

        // Separator
        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            implicitWidth: 1
            color: Appearance.colors.colLayer1
        }

        // Category toggles
        IconToolbarButton {
            id: catGeneral
            implicitWidth: height
            text: "landscape"
            toggled: Wallhaven.categories[0] === "1"
            onClicked: {
                const c = Wallhaven.categories
                Wallhaven.categories = (c[0] === "1" ? "0" : "1") + c[1] + c[2]
            }
            StyledToolTip { text: Translation.tr("General") }
        }
        IconToolbarButton {
            id: catAnime
            implicitWidth: height
            text: "animated_images"
            toggled: Wallhaven.categories[1] === "1"
            onClicked: {
                const c = Wallhaven.categories
                Wallhaven.categories = c[0] + (c[1] === "1" ? "0" : "1") + c[2]
            }
            StyledToolTip { text: Translation.tr("Anime") }
        }
        IconToolbarButton {
            id: catPeople
            implicitWidth: height
            text: "person"
            toggled: Wallhaven.categories[2] === "1"
            onClicked: {
                const c = Wallhaven.categories
                Wallhaven.categories = c[0] + c[1] + (c[2] === "1" ? "0" : "1")
            }
            StyledToolTip { text: Translation.tr("People") }
        }

        // Separator
        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            implicitWidth: 1
            color: Appearance.colors.colLayer1
        }

        StyledComboBox {
            id: sortCombo
            Layout.fillWidth: false
            implicitWidth: 140
            model: [
                Translation.tr("Date Added"),
                Translation.tr("Relevance"),
                Translation.tr("Random"),
                Translation.tr("Views"),
                Translation.tr("Favorites"),
                Translation.tr("Top List"),
            ]
            readonly property var sortValues: [
                "date_added", "relevance", "random", "views", "favorites", "toplist"
            ]
            currentIndex: sortValues.indexOf(Wallhaven.sorting)
            onActivated: index => {
                Wallhaven.sorting = sortValues[index]
            }
        }

        StyledComboBox {
            id: ratioCombo
            Layout.fillWidth: false
            implicitWidth: 110
            model: [
                Translation.tr("Any Ratio"),
                "16x9", "16x10", "21x9", "32x9",
                "4x3", "5x4", "3x2", "1x1",
            ]
            readonly property var ratioValues: [
                "", "16x9", "16x10", "21x9", "32x9",
                "4x3", "5x4", "3x2", "1x1",
            ]
            currentIndex: 0
            onActivated: index => {
                Wallhaven.ratios = ratioValues[index]
            }
        }

        StyledComboBox {
            id: resCombo
            Layout.fillWidth: false
            implicitWidth: 120
            model: [
                Translation.tr("Any Res"),
                "1920x1080", "2560x1440", "3840x2160",
                "2560x1080", "3440x1440", "5120x1440",
            ]
            readonly property var resValues: [
                "", "1920x1080", "2560x1440", "3840x2160",
                "2560x1080", "3440x1440", "5120x1440",
            ]
            currentIndex: 0
            onActivated: index => {
                Wallhaven.atleast = resValues[index]
            }
        }

        // Separator
        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            implicitWidth: 1
            color: Appearance.colors.colLayer1
        }

        // Page nav
        IconToolbarButton {
            implicitWidth: height
            text: "chevron_left"
            enabled: Wallhaven.page > 1
            onClicked: {
                Wallhaven.page = Math.max(1, Wallhaven.page - 1)
                Wallhaven.search(false, false)
            }
        }

        StyledText {
            text: `${Wallhaven.page}/${Wallhaven.lastPage}`
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer2
            horizontalAlignment: Text.AlignHCenter
            Layout.minimumWidth: 40
        }

        IconToolbarButton {
            implicitWidth: height
            text: "chevron_right"
            enabled: Wallhaven.page < Wallhaven.lastPage
            onClicked: {
                Wallhaven.page++
                Wallhaven.search(false, false)
            }
        }
    }
}
