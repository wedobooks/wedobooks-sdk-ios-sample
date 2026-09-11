//
//  EnvironmentCatalog.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 07/09/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import Foundation

/// The environments the sample app can run against, taken from the `Environments.all` list in
/// `Sources/Environments.swift`, plus the persisted record of which one the user picked on the
/// login screen.
///
/// `WeDoBooksFacade.shared.setup(...)` — and the Firebase app it configures — happens once per
/// launch in `MainViewController`, so a different environment only takes effect on the next
/// launch. `EnvironmentPickerView` therefore persists the pick and closes the app instead of
/// swapping anything live.
enum EnvironmentCatalog {
    private static let selectedIdKey = "selectedEnvironmentId"

    /// Every environment in `Environments.all`, in list order. The first one is the default.
    static let all: [Environment] = validated(Environments.all)

    /// The environment to run against — the persisted pick, or the first entry in the list when
    /// nothing is persisted yet (or when the persisted id is no longer in the list).
    static var selected: Environment {
        guard let id = UserDefaults.standard.string(forKey: selectedIdKey),
              let environment = all.first(where: { $0.id == id }) else {
            return all[0]
        }
        return environment
    }

    /// Remembers `environment` as the one to use from the next launch onwards.
    static func select(_ environment: Environment) {
        UserDefaults.standard.set(environment.id, forKey: selectedIdKey)
        // The app is terminated right after picking, which skips the usual flush of defaults.
        UserDefaults.standard.synchronize()
    }

    /// Forgets the picked environment so the next launch falls back to the first entry in the
    /// list. Used to recover from a pick the app cannot actually start against — the picker only
    /// exists on the login screen, which an environment that fails during setup never reaches.
    static func clearSelection() {
        UserDefaults.standard.removeObject(forKey: selectedIdKey)
        UserDefaults.standard.synchronize()
    }

    /// Fails fast on a list the app cannot run against, so the mistake surfaces on the first
    /// launch rather than as a confusing picker.
    private static func validated(_ environments: [Environment]) -> [Environment] {
        guard !environments.isEmpty else {
            fatalError("Environments.all is empty — add at least one environment in Sources/Environments.swift")
        }

        let duplicateIds = Dictionary(grouping: environments, by: \.id).filter { $0.value.count > 1 }.keys
        guard duplicateIds.isEmpty else {
            fatalError("Environments.all reuses the environment id(s) \(duplicateIds.sorted().joined(separator: ", ")) — ids are used to remember the pick and must be unique")
        }

        return environments
    }
}
