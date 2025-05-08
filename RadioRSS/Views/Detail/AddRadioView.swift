//
//  AddRadioView.swift
//  RadioRSS
//
//  Created by Yanis Labbé on 2025-05-07.
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddRadioView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var title = ""
    @State private var urlText = ""
    @State private var picker: PhotosPickerItem?
    @State private var data: Data?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Stream URL", text: $urlText).keyboardType(.URL).textInputAutocapitalization(.never)
                PhotosPicker(selection: $picker, matching: .images) { Label("Image", systemImage: "photo") }
                    .onChange(of: picker) { load() }
                if let d = data, let i = UIImage(data: d) { Image(uiImage: i).resizable().scaledToFit().frame(height: 150) }
            }
            .navigationTitle("New Station")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Add") { add() }.disabled(title.isEmpty || urlText.isEmpty) }
            }
        }
    }

    private func load() {
        Task { if let d = try? await picker?.loadTransferable(type: Data.self) { data = d } }
    }

    private func add() {
        guard let u = URL(string: urlText) else { return }
        context.insert(Radio(title: title, streamURL: u, imageData: data))
        try? context.save()
        dismiss()
    }
}
