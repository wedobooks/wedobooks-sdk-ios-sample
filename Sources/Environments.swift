//
//  Environments.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 08/09/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import WeDoBooksSDK

enum Environments {
    static let all: [Environment] = [
        Environment(
            id: "TODO",
            displayName: "TODO",
            mode: .streaming,
            firebaseFile: "GoogleService-Info-SDK.plist",
            tokenUrl: "$(CUSTOM_TOKEN_URL)"
        ),
    ]
}
