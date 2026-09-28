//
//  SavedValues.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 23/09/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import Foundation

struct SavedValues {
    static let userIds = SavedValues(name: "savedUserIds")
    static let ebookIsbns = SavedValues(name: "savedEbookIsbns")
    static let audiobookIsbns = SavedValues(name: "savedAudiobookIsbns")

    private static let maxCount = 20

    private let name: String

    private init(name: String) {
        self.name = name
    }

    func all(for environment: Environment = currentEnv) -> [String] {
        UserDefaults.standard.stringArray(forKey: key(for: environment)) ?? []
    }

    func save(_ value: String, for environment: Environment = currentEnv) {
        guard !value.isEmpty else { return }
        var values = all(for: environment).filter { $0 != value }
        values.insert(value, at: 0)
        UserDefaults.standard.set(Array(values.prefix(Self.maxCount)), forKey: key(for: environment))
    }

    func remove(_ value: String, for environment: Environment = currentEnv) {
        let values = all(for: environment).filter { $0 != value }
        UserDefaults.standard.set(values, forKey: key(for: environment))
    }

    private func key(for environment: Environment) -> String {
        "\(name).\(environment.id)"
    }
}
