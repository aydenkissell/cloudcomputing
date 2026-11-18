# LifeTrack SwiftUI App

This folder is a native SwiftUI translation of the original LifeTrack web app in `y/`.

## Open in Xcode

1. In Xcode, choose **File → New → Project → iOS → App**.
2. Set the product name to `LifeTrack`, interface to **SwiftUI**, and language to **Swift**.
3. Replace the generated app source with `LifeTrackApp.swift` from this folder.
4. Choose an iPhone simulator or a connected Apple device and press **Run**.

The app includes the original sleep tracker, gym tracker, daily habits, summary score, and recent-entry history. Entries are stored locally with `UserDefaults`, so it works without additional packages or a server.

The original JavaScript also contains a Firebase web configuration and a Firestore workout write. This native version intentionally keeps the app self-contained; Firebase can be added later through Xcode's Swift Package Manager if cloud sync is needed.
