import QtQuick 2.8
import QtQuick.Window 2.0
import QtGraphicalEffects 1.12
import QtQml 2.15
import QtQuick.Layouts 1.1
import "../../../js/enums.mjs" as Enums

import "../../../components"

// SystemActions — action list for the System panel on the dashboard.
// Follows the same pattern as SkinActions.qml / ThemesActions.qml

ActionList {
  focus: true
  model: ListModel {
    ListElement {
      label:      () => "Open Settings"
      action:     () => navigate(pages.settingsDetails)
      canExecute: () => true
    }
    ListElement {
      label:      () => "Choose Theme"
      action:     () => navigate(pages.themesDetails)
      canExecute: () => true
    }
    ListElement {
      label:      () => "Choose Skin"
      action:     () => navigate(pages.skinsDetails)
      canExecute: () => true
    }
    ListElement {
      label:      () => "View Play Time"
      action:     () => navigate(pages.systemDetails)
      canExecute: () => true
    }
    ListElement {
      label:      () => "View Collections"
      action:     () => navigate(pages.systemDetails)
      canExecute: () => true
    }
    ListElement {
      label:      () => "Restart Pegasus"
      action:     () => Qt.quit()
      canExecute: () => true
    }
    ListElement {
      label:      () => "Quit to Desktop"
      action:     () => Qt.quit()
      canExecute: () => true
    }
  }
}
