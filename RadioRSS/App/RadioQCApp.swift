//
//  RadioRSSApp.swift
//  RadioRSS
//
//  Created by Yanis Labbé on 2025-05-07.
//

import SwiftUI
import SwiftData
import AVFoundation

@main
struct RadioRSSApp: App {
    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
        }
    }

    @State private var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Podcast.self,
            Episode.self,
            Radio.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(PlayerViewModel.shared)
        }
        .modelContainer(sharedModelContainer)
    }
}
