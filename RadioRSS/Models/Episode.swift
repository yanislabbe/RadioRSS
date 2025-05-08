//
//  Episode.swift
//  RadioRSS
//
//  Created by Yanis Labbé on 2025-05-07.
//

import Foundation
import SwiftData

@Model
final class Episode {
    @Attribute(.unique) var id: UUID
    var title: String
    var audioURL: URL
    var artworkURL: URL?
    var pubDate: Date
    var duration: Double?
    var localFileURL: URL?
    var progress: Double
    var podcast: Podcast?
    init(title: String, audioURL: URL, artworkURL: URL? = nil, pubDate: Date = Date(), duration: Double? = nil, podcast: Podcast? = nil) {
        self.id = UUID()
        self.title = title
        self.audioURL = audioURL
        self.artworkURL = artworkURL
        self.pubDate = pubDate
        self.duration = duration
        self.localFileURL = nil
        self.progress = 0
        self.podcast = podcast
    }
}
