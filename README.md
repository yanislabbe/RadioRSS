## Overview
RadioRSS is an **iOS 18.4+** app built with SwiftUI/SwiftData. Add any podcast RSS feed or radio stream URL, listen online or offline, and keep playback rolling even when the network drops. Runs in the background and integrates with the iOS Now-Playing center.

## Features
* Add podcasts via RSS (parsed with **FeedKit**)
* Add live radio streams (HTTP/ICY)
* Audio playback with **AVPlayer** – background, system controls, AirPlay
* Episode downloads via background `URLSession` with progress indicator
* Auto-resume after connection loss (radio) & position bookmarking (podcasts)
* Offline library view in the *Downloads* tab
* SwiftUI interface: Stations / Podcasts / Downloads / Settings + mini-player
* Full data reset from *Settings*

## Installation
~~~bash
# Requirements
# - macOS 15.4+
# - Xcode 16.3+
# - iOS 18.4+ device or simulator

git clone https://github.com/yanislabbe/RadioRSS.git
open RadioRSS/RadioRSS.xcodeproj
# Select an iOS target and hit Run (⌘R)
~~~

## Usage
1. **Stations** : tap ➕, enter a title and stream URL (e.g. http://…/stream).  
2. **Podcasts** : tap ➕, paste the RSS feed URL (e.g. https://…/feed.xml).  
3. Tap a row to start playback – the mini player appears.  
4. In the full player : ⏮ / ⏯ / ⏭, seek bar (podcasts) or “LIVE” badge (radio).  
5. Manage offline files in the *Downloads* tab.

## Configuration
| Key                           | File                     | Purpose                               |
|-------------------------------|--------------------------|---------------------------------------|
| `UIBackgroundModes: audio`    | *Info.plist*             | Enables background audio              |
| Entitlements (empty)          | *RadioRSS.entitlements*  | Add extra capabilities if needed      |
| SPM package: `FeedKit`        | Xcode > Package Dependencies | RSS parsing                        |

No environment variables required.

## Tests
No automated tests yet.  

## Contributing
1. Fork → feature branch `feat/…`.  
2. Run `swiftlint` before committing.  
3. Use Conventional Commits (`feat:`, `fix:`…).  
4. Open a Pull Request to *main*; a maintainer will squash-merge.

## License
MIT © 2025 Yanis Labbé
