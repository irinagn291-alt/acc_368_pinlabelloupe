import SwiftUI

struct ComparisonView: View {
    @EnvironmentObject private var journal: Journal
    let pick: (Int) -> Void
    private func label(at index: Int) -> FoodProduct? {
        guard journal.archive.comparison.indices.contains(index), let id = journal.archive.comparison[index] else { return nil }
        return journal.archive.products[id]
    }

    var body: some View {
        PageBody {
            FieldHeading(index: "02   /   SIDE BY SIDE", title: "Compare")
            Text("Put two labels side by side. Every value is shown per 100 g.").foregroundStyle(Ink.muted)
            VStack(spacing: 8) { ForEach(0..<2) { i in slot(i) } }
            if let a = label(at: 0), let b = label(at: 1) {
                HStack { IndexTag(text: "Nutrient"); Spacer(); IndexTag(text: "A").frame(width: 57); IndexTag(text: "B").frame(width: 57); IndexTag(text: "B − A").frame(width: 58) }
                VStack(spacing: 0) {
                    ForEach(Measure.all) { m in
                        let l = a[keyPath: m.value], r = b[keyPath: m.value]
                        HStack(spacing: 4) {
                            VStack(alignment: .leading) { Text(m.name).font(.subheadline); Text(m.unit).font(.caption2).foregroundStyle(Ink.muted) }
                            Spacer(minLength: 1)
                            Text(fieldNumber(l)).frame(width: 57); Text(fieldNumber(r)).frame(width: 57)
                            Text(delta(l, r)).frame(width: 58).foregroundStyle(Ink.blue)
                        }.font(.body.monospacedDigit()).padding(.vertical, 9)
                        Divider()
                    }
                }
                Text("B − A is the difference per 100 g. A dash indicates missing label data.").font(.footnote).foregroundStyle(Ink.muted)
            } else {
                FieldEmpty(title: "Pick a pair", description: "Choose two products above, or add one from an open dossier.")
            }
        }.buttonStyle(.plain).toolbar(.hidden, for: .navigationBar)
    }

    private func delta(_ a: Double?, _ b: Double?) -> String {
        guard let a, let b else { return "—" }
        let d = ((b - a) * 100).rounded() / 100
        return (d > 0 ? "+" : "") + fieldNumber(d)
    }

    private func slot(_ i: Int) -> some View {
        let p = label(at: i)
        return HStack(spacing: 12) {
            Text(i == 0 ? "A" : "B").font(.system(.title, design: .serif).italic()).foregroundStyle(Ink.lemon).frame(width: 46, height: 54).background(Ink.blue)
            if let p {
                Button { pick(i) } label: { VStack(alignment: .leading, spacing: 3) { Text(p.name).font(.headline); Text("Replace").font(.caption).foregroundStyle(Ink.blue) }.frame(maxWidth: .infinity, alignment: .leading) }
                Button { journal.clearSlot(p.id) } label: { Image(systemName: "xmark.circle").padding(10) }.accessibilityLabel("Remove " + p.name)
            } else {
                Button { pick(i) } label: { Label("Choose a label", systemImage: "plus").frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 12) }.accessibilityIdentifier("compare.pick.\(i)")
            }
        }.padding(9).background(Ink.white).overlay { Rectangle().strokeBorder(Ink.rule) }
    }
}
