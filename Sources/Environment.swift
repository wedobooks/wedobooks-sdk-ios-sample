//
//  Environment.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 17/03/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import Foundation
import WeDoBooksSDK

/// Selects whether the host app manages start positions ("custom progress") per format.
/// When a flag is `false` the SDK restores its own saved bookmark on open and rejects a
/// host-supplied start position; when `true` the host controls the initial position
/// (audiobook via `setInitialPlayerTimestampSeconds` / headless `loadBook(startPosition:)`,
/// ebook via `setInitialReaderCfi`). Flip a flag to enable that format's custom progress.
enum SampleProgressConfig {
    static let customReaderProgress = false
    static let customPlayerProgress = false
}

struct Environment {
    let mode: WeDoBooksFacade.Mode
    let firebaseFile: String
    let userId: String
    let tokenUrl: String
    let audioBookIsbn: String
    let ebookIsbn: String

    var modeDisplayName: String {
        switch mode {
        case .streaming: return "Streaming"
        case .library: return "Library"
        @unknown default: return "Unknown"
        }
    }

    /// Firebase project ID read from the configured GoogleService-Info plist; shown in the header subtitle.
    var name: String {
        guard let path = Bundle.main.path(forResource: firebaseFile, ofType: nil),
              let dict = NSDictionary(contentsOfFile: path),
              let projectId = dict["PROJECT_ID"] as? String else {
            return "unknown-project"
        }
        return projectId
    }
}

let currentEnv = Environment(
    mode: // .streaming or .library,
    firebaseFile: "TODO", // Fill in correct name here for example GoogleService-Info-SDK.plist if that's the name of the file in the main bundle of the app
    userId: Bundle.main.infoDictionary!["USER_ID"] as! String, // Forcing crash here if value is missing as the example app won't work without it
    tokenUrl: (Bundle.main.infoDictionary?["CUSTOM_TOKEN_URL"] as! String).removingPercentEncoding!, // Forcing crash here if value is missing as the example app won't work without it
    audioBookIsbn: "TODO", // Fill in isbn from catalog here
    ebookIsbn: "TODO" // Fill in isbn from catalog here
)
