//
//  Environment.swift
//  WeDoBooksSDKSample
//
//  Created by Bo Gosmer on 17/03/2026.
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
}

let currentEnv = Environment(
    mode: // .streaming or .library,
    firebaseFile: "TODO", // Fill in correct name here for example GoogleService-Info-SDK.plist if that's the name of the file in the main bundle of the app
    userId: Bundle.main.infoDictionary!["USER_ID"] as! String, // Forcing crash here if value is missing as the example app won't work without it
    tokenUrl: (Bundle.main.infoDictionary?["CUSTOM_TOKEN_URL"] as! String).removingPercentEncoding!, // Forcing crash here if value is missing as the example app won't work without it
    audioBookIsbn: "TODO", // Fill in isbn from catalog here
    ebookIsbn: "TODO" // Fill in isbn from catalog here
)
