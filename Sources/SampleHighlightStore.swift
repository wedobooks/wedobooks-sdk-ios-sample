//
//  SampleHighlightStore.swift
//  WeDoBooksSDKSample
//
//  Created by Kristoffer Frank on 10/11/2026.
//  Copyright © 2026 WeDoBooks A/S. All rights reserved.
//

import Foundation
import WeDoBooksSDK

/// Keeps reader highlights in memory. The reader asks for a book's highlights when it opens and
/// reports every highlight the user saves or deletes.
actor SampleHighlightStore: HighlightCallback {
    static let shared = SampleHighlightStore()

    private var highlights: [Highlight] = []

    private init() {}

    func loadHighlights(materialId: String) async throws -> [Highlight]? {
        let bookHighlights = highlights.filter { $0.materialId == materialId }
        EventBanner.show("Highlights loaded: \(bookHighlights.count) for \(materialId)")
        return bookHighlights
    }

    func didSave(_ highlight: Highlight) async throws {
        highlights.removeAll { $0.id == highlight.id }
        highlights.append(highlight)
        EventBanner.show("Highlight saved: \(highlight.selectionText.prefix(40))")
    }

    func didDelete(_ highlight: Highlight) async throws {
        highlights.removeAll { $0.id == highlight.id }
        EventBanner.show("Highlight deleted: \(highlight.selectionText.prefix(40))")
    }
}
