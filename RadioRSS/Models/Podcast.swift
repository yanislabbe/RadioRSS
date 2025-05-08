//
//  Podcast.swift
//  RadioRSS
//
//  Created by Yanis Labbé on 2025-05-07.
//

import Foundation
import SwiftData

@Model
final class Podcast {
    @Attribute(.unique) var id: UUID
    var title: String
    var feedURL: URL
    var artworkURL: URL?
    var episodes: [Episode]
    init(title: String, feedURL: URL, artworkURL: URL? = nil) {
        self.id = UUID()
        self.title = title
        self.feedURL = feedURL
        self.artworkURL = artworkURL
        self.episodes = []
    }
}
