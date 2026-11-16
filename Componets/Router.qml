import QtQuick 2.8
import "../js/enums.mjs" as Enums

Loader {
  id: pageLoader
  focus: true
  asynchronous: true
  anchors.fill: parent

  property alias loader: pageLoader
  property alias currentItem: pageLoader.item

  readonly property var pages: {
    "library": {
      path: "library/LibraryPage.qml",
      showStage: true
    },
    "gameDetails": {
      path: "details/DetailsPage.qml",
      showStage: false
    },
    "gamerDetails": {
      path: "details/GamerPage.qml",
      showStage: false
    },
    "libraryDetails": {
      path: "details/GameLibraryPage.qml",
      showStage: false
    },
    "settingsDetails": {
      path: "details/SettingsPage.qml",
      showStage: false
    },
    "systemDetails": {
      path: "details/SystemPage.qml",
      showStage: false
    },
    "skinsDetails": {
      path: "details/SkinsPage.qml",
      showStage: false
    },
    "themesDetails": {
      path: "details/components/ThemesDetails.qml",
      showStage: false
    },
    "musicPlayer": {
      path: "Music/MusicPage.qml",
      showStage: false
    },
    "musicDetails": {
      path: "Music/MusicDetails.qml",
      showStage: false
    },
    "musicViewer": {
      path: "Music/MusicImageViewer.qml",
      showStage: false
    },
    "videoPlayer": {
      path: "Video/VideoPage.qml",
      showStage: false
    },
    "profileScene": {
      path: "details/components/ProfileScene.qml",
      showStage: true
    },
    "videoDetails": {
      path: "Video/VideoDetails.qml",
      showStage: false
    },
    "Emulators": {
      path: "emulators/emudetails.qml",
      showStage: true
    },
    "Genres": {
      path: "genres/genredetails.qml",
      showStage: false
    },
    "genreeditor": {
     path: "genres/genreeditor.qml",
     showStage: false
    },
    "Files": {
     path: "files/Files.qml",
     showStage: false
    } 
  }

function navigate(page, params) {
    params = params || {};

    Object.keys(params).forEach(function(key) {
        api.memory.set(key, typeof params[key] === "object"
          ? JSON.stringify(params[key])
          : String(params[key]));
    });

    delay(() => {
        stage.state = page.showStage ? "Visible" : "Invisible";
        pageLoader.source = `../pages/${page.path}`;
    }, 240); // delay page change until button press animation and sound is complete
  }

  // Inject navigate + pages into every loaded page so they can call navigate() themselves
  onLoaded: {
    if (item && item.hasOwnProperty("navigate")) item.navigate = pageLoader.navigate;
    if (item && item.hasOwnProperty("pages"))    item.pages    = pageLoader.pages;
  }

  Component.onCompleted: {
    navigate(pages.library);
  }
}
