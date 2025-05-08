//
//  ContentView.swift
//  RadioRSS
//
//  Created by Yanis Labbé on 2025-05-07.
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    @EnvironmentObject private var player: PlayerViewModel

    var body: some View {
        TabView(selection: $selection) {
            RadiosView()
                .tag(0)
                .tabItem { Label("Stations", systemImage: "antenna.radiowaves.left.and.right") }
            PodcastsView()
                .tag(1)
                .tabItem { Label("Podcasts", systemImage: "mic.fill") }
            RecordingsView()
                .tag(2)
                .tabItem { Label("Downloads", systemImage: "tray.and.arrow.down.fill") }
            SettingsView()
                .tag(3)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .overlay(alignment: .bottom) {
            MiniPlayerView()
                .padding(.bottom, 49)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .alert(player.networkAlert ?? "",
               isPresented: Binding(get: { player.networkAlert != nil },
                                    set: { if !$0 { player.networkAlert = nil } })) {
            Button("OK", role: .cancel) {}
        }
                                    .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
