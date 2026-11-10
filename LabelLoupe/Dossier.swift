import SwiftUI

struct Measure: Identifiable {
    let name: String
    let unit: String
    let value: KeyPath<FoodProduct, Double?>
    var id: String { name }
    static let all = [
        Measure(name: "Energy", unit: "kcal", value: \.kcal),
        Measure(name: "Protein", unit: "g", value: \.protein),
        Measure(name: "Fat", unit: "g", value: \.fat),
        Measure(name: "Carbs", unit: "g", value: \.carbs),
        Measure(name: "Sugars", unit: "g", value: \.sugar),
        Measure(name: "Fiber", unit: "g", value: \.fiber),
        Measure(name: "Salt", unit: "g", value: \.salt)
    ]
}

struct DossierView: View {
    @EnvironmentObject private var journal: Journal
    let product: FoodProduct
    let openComparison: () -> Void
    @State private var replace = false
    @State private var recorded = false
    private var saved: Bool { journal.archive.collection.contains(product.id) }

    var body: some View {
        PageBody {
            IndexTag(text: isCatalog ? "Dossier  /  \(product.id)" : "Dossier  /  manual entry").foregroundStyle(Ink.blue)
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.name).font(.system(.largeTitle, design: .serif).weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                    if !product.brand.isEmpty { Text(product.brand).font(.headline).foregroundStyle(Ink.muted) }
                }
                Spacer(minLength: 0)
                if let url = product.imageURL {
                    AsyncImage(url: url) { image in image.resizable().scaledToFit() } placeholder: { Image(systemName: "shippingbox") }
                        .frame(width: 60, height: 78).padding(6).background(.white)
                }
            }
            Button { recorded = journal.record(product.id) } label: {
                ActionLabel(title: "Log a choice", icon: "checkmark.seal")
            }
.accessibilityIdentifier("dossier.log")
            if recorded { Label("Choice added to your history", systemImage: "checkmark.circle.fill").font(.subheadline).foregroundStyle(Ink.blue).accessibilityAddTraits(.updatesFrequently) }
            ViewThatFits {
                HStack { controls }
                VStack(alignment: .leading) { controls }
            }
            Divider()
            IndexTag(text: "01  /  Ingredients").foregroundStyle(Ink.blue)
            Text(product.ingredients?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? "Ingredients are unlisted. Check the package.").font(.body)
            IndexTag(text: "02  /  Allergens").foregroundStyle(Ink.blue)
            if product.allergens.isEmpty { FieldEmpty(title: "No allergen data", description: "Check the ingredient list and allergen warnings on the package.") }
            else { Text(product.allergens.map(allergenLabel).joined(separator: "  ·  ")).font(.headline) }
            IndexTag(text: "03  /  Per 100 g").foregroundStyle(Ink.blue)
            VStack(spacing: 0) {
                ForEach(Measure.all) { m in
                    HStack { Text(m.name); Spacer(); Text(fieldNumber(product[keyPath: m.value])).monospacedDigit().bold(); Text(m.unit).font(.caption).foregroundStyle(Ink.muted) }
                        .padding(.vertical, 9)
                    Divider()
                }
            }
            Text("A dash indicates an unlisted value.").font(.caption).foregroundStyle(Ink.muted)
            if isCatalog, let link = URL(string: "https://world.openfoodfacts.org/product/" + product.id) {
                Link(destination: link) { Label("View on Open Food Facts", systemImage: "arrow.up.right.square") }.foregroundStyle(Ink.blue)
            } else { Text("Manually entered label").font(.caption) }
        }
        .buttonStyle(.plain).navigationTitle("Dossier").navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Which label should this replace?", isPresented: $replace) {
            ForEach(Array(journal.archive.comparison.enumerated()), id: \.element) { index, id in
                if let id { Button(journal.archive.products[id]?.name ?? "Label") { journal.compare(product.id, at: index); openComparison() } }
            }
        }
    }
    private var isCatalog: Bool { !product.id.isEmpty && product.id.allSatisfy(\.isNumber) }
    @ViewBuilder private var controls: some View {
        Button { journal.toggleSaved(product.id) } label: {
            Label(saved ? "Saved" : "Save label", systemImage: saved ? "bookmark.fill" : "bookmark").padding(10)
        }.accessibilityIdentifier("dossier.save").accessibilityHint(saved ? "Remove from collection" : "Add to collection")
        Button {
            if !journal.archive.comparison.contains(nil) && !journal.archive.comparison.contains(product.id) { replace = true } else { openComparison() }
        } label: { Label("Compare", systemImage: "rectangle.split.2x1").padding(10) }.accessibilityIdentifier("dossier.compare")
    }
}

private extension String { var nonEmpty: String? { isEmpty ? nil : self } }
private func allergenLabel(_ tag: String) -> String {
    let key = tag.components(separatedBy: ":").last ?? tag
    let titles = ["milk": "Milk", "gluten": "Gluten", "eggs": "Eggs", "peanuts": "Peanuts", "soybeans": "Soybeans", "nuts": "Tree nuts", "fish": "Fish", "celery": "Celery", "mustard": "Mustard", "sesame-seeds": "Sesame", "crustaceans": "Crustaceans", "molluscs": "Molluscs", "lupin": "Lupin", "sulphur-dioxide-and-sulphites": "Sulfur dioxide and sulfites"]
    return titles[key] ?? key.replacingOccurrences(of: "-", with: " ")
}
