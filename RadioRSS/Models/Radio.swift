//
//  Radio.swift
//  RadioRSS
//
//  Created by Yanis Labbé on 2025-05-07.
//

import Foundation
import SwiftData

@Model
final class Radio {
    @Attribute(.unique) var id: UUID
    var title: String
    var streamURL: URL
    var imageData: Data?
    init(title: String, streamURL: URL, imageData: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.streamURL = streamURL
        self.imageData = imageData
    }
}
