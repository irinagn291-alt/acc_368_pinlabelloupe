import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject private var journal: Journal
    @Binding var showHistory: Bool
    @State private var query = ""
    @State private var remove: Choice?

    private var saved: [FoodProduct] {
        journal.archive.collection.compactMap { journal.archive.products[$0] }.filter { query.isEmpty || ($0.name + " " + $0.brand).localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        PageBody {
            FieldHeading(index: "03   /   PERSONAL INDEX", title: "Archive")
            Picker("Section", selection: $showHistory) { Text("Collection").tag(false); Text("Choice history").tag(true) }.pickerStyle(.segmented)
            if showHistory {
                IndexTag(text: "Entries  /  \(journal.archive.choices.count)")
                if journal.archive.choices.isEmpty {
                    FieldEmpty(title: "Your history is empty", description: "Tap Log a choice on a product you pick. Its name and the time will appear here.")
                } else {
                    ForEach(journal.archive.choices) { event in
                        if let p = journal.archive.products[event.productID] {
                            HStack {
                                NavigationLink(value: p.id) { ProductLine(product: p, mark: "checkmark.seal", detail: event.date.formatted(.dateTime.locale(Locale(identifier: "en_US")).day().month(.wide).year().hour().minute())) }
                                Button { remove = event } label: { Image(systemName: "trash").font(.subheadline).padding(10).foregroundStyle(Ink.muted) }.accessibilityLabel("Delete choice")
                            }
                            Divider()
                        }
                    }
                }
            } else {
                HStack { Image(systemName: "magnifyingglass"); TextField("Filter by name or brand", text: $query).textInputAutocapitalization(.never)
                    if !query.isEmpty { Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel("Clear filter") }
                }.padding(12).background(Ink.white).overlay { Rectangle().strokeBorder(Ink.rule) }
                if saved.isEmpty {
                    FieldEmpty(title: query.isEmpty ? "An empty shelf" : "No matches", description: query.isEmpty ? "Save a label from its dossier to keep it in your collection." : "Try a different part of the name.")
                } else {
                    ForEach(saved) { p in NavigationLink(value: p.id) { ProductLine(product: p, mark: "bookmark.fill") }; Divider() }
                }
            }
        }.toolbar(.hidden, for: .navigationBar).buttonStyle(.plain)
        .confirmationDialog("Delete this choice from your history?", isPresented: Binding(get: { remove != nil }, set: { if !$0 { remove = nil } })) {
            Button("Delete choice", role: .destructive) { if let remove { journal.removeEvent(remove.id) }; remove = nil }
        }
    }
}
