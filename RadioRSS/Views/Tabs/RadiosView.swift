//
//  RadiosView.swift
//  RadioRSS
//
//  Created by Yanis Labbé on 2025-05-07.
//

import SwiftUI
import SwiftData

struct RadiosView: View {
    @Environment(\.modelContext) private var context
    @Query private var radios: [Radio]
    @State private var search = ""
    @State private var add = false
    @State private var target: Radio?
    @EnvironmentObject private var player: PlayerViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { r in
                    HStack {
                        image(for: r)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text(r.title)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { player.play(radio: r) }
                    .swipeActions {
                        Button(role: .destructive) { target = r } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .searchable(text: $search)
            .navigationTitle("Stations")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { add = true } label: { Image(systemName: "plus") } } }
            .sheet(isPresented: $add) { AddRadioView() }
            .alert("Delete this station?", isPresented: Binding(get: { target != nil }, set: { if !$0 { target = nil } })) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let r = target { context.delete(r); try? context.save() }
                    target = nil
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if player.currentEpisode != nil || player.currentRadio != nil {
                Color.clear.frame(height: 56)
            }
        }
    }

    private var filtered: [Radio] { search.isEmpty ? radios : radios.filter { $0.title.localizedCaseInsensitiveContains(search) } }

    @ViewBuilder private func image(for r: Radio) -> some View {
        if let d = r.imageData, let ui = UIImage(data: d) { Image(uiImage: ui).resizable().scaledToFill() } else { Color.gray }
    }
}
