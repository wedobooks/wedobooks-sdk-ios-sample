//
//  Environment.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 17/03/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import Foundation
import WeDoBooksSDK

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
    mode: .streaming,// .streaming or .library,
    firebaseFile: "GoogleService-Info-IR-SDK.plist", // Fill in correct name here for example GoogleService-Info-SDK.plist if that's the name of the file in the main bundle of the app
    userId: Bundle.main.infoDictionary!["USER_ID"] as! String, // Forcing crash here if value is missing as the example app won't work without it
    tokenUrl: (Bundle.main.infoDictionary?["CUSTOM_TOKEN_URL"] as! String).removingPercentEncoding!, // Forcing crash here if value is missing as the example app won't work without it
    audioBookIsbn: "TODO", // Fill in isbn from catalog here
    ebookIsbn: "TODO" // Fill in isbn from catalog here
)
