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
    mode: .streaming,
    firebaseFile: "GoogleService-Info-SDK.plist",
    userId: Bundle.main.infoDictionary!["USER_ID"] as! String,
    tokenUrl: (Bundle.main.infoDictionary?["CUSTOM_TOKEN_URL"] as! String).removingPercentEncoding!,
    audioBookIsbn: "TODO",
    ebookIsbn: "TODO"
)
