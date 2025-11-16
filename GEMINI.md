# GEMINI.md

## Project Overview

This is the iOS source code for the "黄庭禅" (Huáng Tíng Chán) application. It is a media-heavy app with a focus on audio and video playback, likely related to Chan Buddhism. The app features social sharing and push notifications.

The project is written in Swift and uses CocoaPods for dependency management. The main navigation is a tab bar with five sections: Home, Album, a central play button, Video, and Profile.

## Building and Running

To build and run this project, you will need Xcode and CocoaPods installed.

1.  **Install Dependencies:**
    ```bash
    pod install
    ```

2.  **Open the Workspace:**
    Open the `htz.xcworkspace` file in Xcode.

3.  **Run the App:**
    Select a simulator or a connected device and click the "Run" button in Xcode.

## Development Conventions

*   **UI:** The UI is built programmatically using SnapKit for Auto Layout.
*   **Networking:** Moya is used for networking, built on top of Alamofire.
*   **JSON Parsing:** SwiftyJSON and HandyJSON are used for parsing JSON data.
*   **Image Handling:** Kingfisher is used for downloading and caching images.
*   **Media Playback:** The app uses ZFPlayer, FreeStreamer, and IJKMediaFramework for audio and video playback.
*   **Social Integration:** The app integrates with Weibo, Wechat, and Tencent QQ for sharing.
*   **Push Notifications:** JPush is used for push notifications.
*   **Local Storage:** Core Data is used for local data persistence.
*   **Tab Bar:** The tab bar is dynamically configured from the `htz/htz/Resource/TabBar/menu.json` file.
