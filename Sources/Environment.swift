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

/// One backend the sample app can run against, listed in `Sources/Environments.swift`.
/// See `EnvironmentCatalog` for validation and for how the environment is picked at runtime.
struct Environment {
    /// Stable key used to remember the picked environment across launches. Not shown in the UI.
    let id: String
    /// Name shown in the environment picker on the login screen.
    let displayName: String
    let mode: WeDoBooksFacade.Mode
    let firebaseFile: String
    let tokenUrl: String

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

    // MARK: Init

    /// Every value except `id` may be written as `$(SOME_KEY)` to pull the value from `Info.plist`
    /// at runtime instead of hardcoding it — which is how the token URL keeps coming from the
    /// gitignored `Resources/Secrets.xcconfig` rather than from this public repo. (`id` stays
    /// literal because it is the key the picked environment is remembered under.) Resolved values
    /// are percent-decoded, as an xcconfig cannot hold a raw `//`.
    init(
        id: String,
        displayName: String,
        mode: WeDoBooksFacade.Mode,
        firebaseFile: String,
        tokenUrl: String
    ) {
        self.id = id
        self.displayName = displayName
        self.mode = mode
        self.firebaseFile = Environment.resolvingInfoPlistReference(firebaseFile)
        self.tokenUrl = Environment.resolvingInfoPlistReference(tokenUrl)
    }

    private static func resolvingInfoPlistReference(_ value: String) -> String {
        guard value.hasPrefix("$("), value.hasSuffix(")") else { return value }

        let key = String(value.dropFirst(2).dropLast())
        guard let resolved = Bundle.main.infoDictionary?[key] as? String, !resolved.isEmpty else {
            // Forcing crash here if value is missing as the example app won't work without it
            fatalError("Environments.swift refers to \(value), but Info.plist has no non-empty \"\(key)\" — check Resources/Secrets.xcconfig")
        }
        return resolved.removingPercentEncoding ?? resolved
    }
}

/// The environment this launch runs against. Picking another one on the login screen persists the
/// choice and closes the app, so this stays constant for the lifetime of the process.
let currentEnv = EnvironmentCatalog.selected
