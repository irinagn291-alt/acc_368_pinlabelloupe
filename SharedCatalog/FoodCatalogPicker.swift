import SwiftUI

struct FoodCatalogPicker: View {
    let onPick: (FoodProduct) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var library = FoodCatalog.merge(FoodCatalog.saved, FoodCatalog.bundled)
    @State private var networkResults: [FoodProduct] = []
    @State private var status: String?
    @State private var loading = false
    @State private var request: Task<Void, Never>?
    @State private var generation = UUID()
    @State private var scanner = false
    @State private var manual = false
    @FocusState private var focused: Bool

    init(onPick: @escaping (FoodProduct) -> Void) {
        self.onPick = onPick
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.enabled && ScreenshotLaunch.screen == "manual-entry" {
            _manual = State(initialValue: true)
        }
        #endif
    }

    private var query: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var visible: [FoodProduct] { FoodCatalog.merge(networkResults, FoodCatalog.local(query, in: library)) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("Name, brand or barcode", text: Binding(get: { text }, set: { text = $0; invalidate() }))
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .focused($focused).submitLabel(.search).onSubmit { search(query) }
                        if !text.isEmpty {
                            Button { text = ""; invalidate() } label: { Image(systemName: "xmark.circle.fill") }
                                .buttonStyle(.plain).accessibilityLabel("Clear search")
                        }
                    }
                    Button { search(query) } label: {
                        Label("Search Open Food Facts", systemImage: "globe")
                    }.disabled(query.count < 2 || loading)
                    Button { focused = false; scanner = true } label: {
                        Label("Scan a barcode", systemImage: "barcode.viewfinder")
                    }
                }
                if loading { HStack { ProgressView(); Text("Searching the catalog…") } }
                if let status { Text(status).font(.callout).foregroundStyle(.secondary) }
                if !visible.isEmpty {
                    Section {
                        ForEach(visible) { product in
                            Button {
                                FoodCatalog.remember([product])
                                dismiss()
                                onPick(product)
                            } label: {
                                HStack(spacing: 13) {
                                    thumbnail(product)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.name).font(.headline).foregroundStyle(.primary).lineLimit(3)
                                        if !product.brand.isEmpty {
                                            Text(product.brand).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
                                }.padding(.vertical, 2)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text(networkResults.isEmpty ? "On this device" : "Search results")
                    }
                } else if !loading && status == nil {
                    Text("No matches on this device. Search Open Food Facts or enter the details from the label.")
                        .font(.callout).foregroundStyle(.secondary)
                }
                Section {
                    Button { focused = false; manual = true } label: {
                        Label("Enter label by hand", systemImage: "square.and.pencil")
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Product data comes from Open Food Facts contributors. Check the package for the current ingredients.")
                        Link("Open Food Facts · Data ODbL · Photos CC BY-SA", destination: URL(string: "https://world.openfoodfacts.org/terms-of-use")!)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Food catalog")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .onDisappear { request?.cancel() }
            .sheet(isPresented: $scanner) {
                FoodScanner { scanned in
                    scanner = false
                    text = scanned
                    search(scanned)
                }
            }
            .navigationDestination(isPresented: $manual) {
                ManualFoodEntry(initialName: FoodCatalog.barcode(query) == nil ? query : "") { product in
                    FoodCatalog.remember([product])
                    dismiss()
                    onPick(product)
                }
            }
        }
    }

    @ViewBuilder private func thumbnail(_ product: FoodProduct) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9).fill(.quaternary)
            Image(systemName: "shippingbox").foregroundStyle(.secondary)
            if let url = product.imageURL, url.scheme == "https" {
                AsyncImage(url: url) { phase in
                    if let image = phase.image { image.resizable().scaledToFit().background(.white) }
                }
            }
        }.frame(width: 44, height: 46).clipShape(RoundedRectangle(cornerRadius: 9)).accessibilityHidden(true)
    }

    private func invalidate() {
        request?.cancel()
        generation = UUID()
        loading = false
        status = nil
        networkResults = []
    }
    private func search(_ raw: String) {
        let term = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard term.count >= 2 else { return }
        invalidate()
        let token = generation
        focused = false
        loading = true
        request = Task { @MainActor in
            defer { if generation == token { loading = false } }
            do {
                let products = try await FoodCatalog.remote(term)
                guard !Task.isCancelled, generation == token else { return }
                networkResults = products
                FoodCatalog.remember(products)
                library = FoodCatalog.merge(products, library)
                status = products.isEmpty ? "No matches in Open Food Facts." : nil
            } catch {
                guard !Task.isCancelled, generation == token else { return }
                status = (error as? CatalogIssue)?.errorDescription ??
                    "Couldn’t reach the catalog. Use a saved product or enter the label by hand."
            }
        }
    }
}

private struct ManualFoodEntry: View {
    @State private var name: String
    @State private var brand = ""
    @State private var kcal = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var ingredients = ""
    let onSave: (FoodProduct) -> Void
    init(initialName: String, onSave: @escaping (FoodProduct) -> Void) {
        _name = State(initialValue: initialName)
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.enabled && ScreenshotLaunch.screen == "manual-entry" {
            _name = State(initialValue: "Toasted Oat Granola")
            _brand = State(initialValue: "Meadow Pantry")
            _kcal = State(initialValue: "420")
            _protein = State(initialValue: "10")
            _carbs = State(initialValue: "58")
            _fat = State(initialValue: "16")
            _ingredients = State(initialValue: "Oats, seeds, honey")
        }
        #endif
        self.onSave = onSave
    }
    private func number(_ text: String) -> Double? { Double(text.replacingOccurrences(of: ",", with: ".")) }
    private func valid(_ input: String, limit: Double) -> Bool {
        input.isEmpty || number(input).map { $0.isFinite && (0...limit).contains($0) } == true
    }
    var body: some View {
        Form {
            Section("Product") { TextField("Product name", text: $name); TextField("Brand", text: $brand) }
            Section {
                field("Energy, kcal", $kcal)
                field("Protein, g", $protein)
                field("Carbohydrates, g", $carbs)
                field("Fat, g", $fat)
            } header: { Text("Per 100 g") } footer: { Text("Leave a field empty if the value is missing from the label.") }
            Section("Ingredients") { TextField("Ingredient list from the package", text: $ingredients, axis: .vertical).lineLimit(2...6) }
            Button("Use this product") {
                let product = FoodProduct(id: "manual-" + UUID().uuidString,
                                          name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                          brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
                                          kcal: number(kcal), protein: number(protein), carbs: number(carbs), fat: number(fat),
                                          ingredients: ingredients.isEmpty ? nil : ingredients)
                onSave(product)
            }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                       !valid(kcal, limit: 1000) || !valid(protein, limit: 100) ||
                       !valid(carbs, limit: 100) || !valid(fat, limit: 100))
        }.navigationTitle("New product").navigationBarTitleDisplayMode(.inline)
    }
    private func field(_ label: String, _ value: Binding<String>) -> some View {
        LabeledContent(label) {
            TextField("—", text: value).multilineTextAlignment(.trailing).keyboardType(.decimalPad)
                .accessibilityLabel(label)
        }
    }
}
