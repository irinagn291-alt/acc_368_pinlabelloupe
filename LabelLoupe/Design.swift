import SwiftUI

enum Ink {
    static let paper = Color(red: 0.966, green: 0.957, blue: 0.923)
    static let white = Color(red: 1, green: 0.996, blue: 0.974)
    static let blue = Color(red: 0.09, green: 0.21, blue: 0.72)
    static let dark = Color(red: 0.095, green: 0.11, blue: 0.15)
    static let muted = Color(red: 0.33, green: 0.34, blue: 0.36)
    static let lemon = Color(red: 0.94, green: 0.97, blue: 0.55)
    static let rule = dark.opacity(0.23)
}

func fieldNumber(_ value: Double?) -> String {
    guard let value, value.isFinite else { return "—" }
    return value.formatted(.number.locale(Locale(identifier: "en_US")).precision(.fractionLength(0...2)))
}

struct IndexTag: View {
    let text: String
    var body: some View { Text(text.uppercased()).font(.system(.caption2, design: .monospaced).weight(.semibold)).tracking(1.1) }
}

struct FieldHeading: View {
    let index: String
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            IndexTag(text: index).foregroundStyle(Ink.blue)
            Text(title).font(.system(.largeTitle, design: .serif).weight(.semibold)).foregroundStyle(Ink.dark)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SpecimenSeal: View {
    var body: some View {
        Canvas { ctx, size in
            let side = min(size.width, size.height)
            ctx.translateBy(x: (size.width - side)/2, y: (size.height - side)/2)
            ctx.scaleBy(x: side/100, y: side/100)
            let ink = GraphicsContext.Shading.color(Ink.lemon)
            for r in [35.0, 39] {
                ctx.stroke(Path(ellipseIn: CGRect(x: 50-r, y: 43-r, width: 2*r, height: 2*r)), with: ink, lineWidth: 0.9)
            }
            var slashes = Path()
            for x in stride(from: 24, through: 74, by: 3) {
                let offset = Double(abs(50-x)) * 0.22
                slashes.move(to: CGPoint(x: Double(x), y: 26+offset))
                slashes.addLine(to: CGPoint(x: Double(x), y: 59-offset))
                if x.isMultiple(of: 2) {
                    slashes.move(to: CGPoint(x: Double(x)+1, y: 26+offset))
                    slashes.addLine(to: CGPoint(x: Double(x)+1, y: 59-offset))
                }
            }
            ctx.stroke(slashes, with: ink, lineWidth: 0.9)
            var cross = Path()
            for y in [8, 78] { cross.move(to: CGPoint(x: 50, y: y-6)); cross.addLine(to: CGPoint(x: 50,y: y+6)) }
            for x in [14, 86] { cross.move(to: CGPoint(x: x-6, y: 43)); cross.addLine(to: CGPoint(x: x+6,y: 43)) }
            ctx.stroke(cross, with: ink, lineWidth: 1.25)
        }.accessibilityHidden(true)
    }
}

struct ProductLine: View {
    let product: FoodProduct
    var mark = "tag"
    var detail: String?
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: mark).font(.body.weight(.medium)).foregroundStyle(Ink.blue)
                .frame(width: 38, height: 44).background(Ink.blue.opacity(0.08))
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name).font(.headline).foregroundStyle(Ink.dark).lineLimit(2)
                Text(detail ?? (product.brand.isEmpty ? "Brand unlisted" : product.brand)).font(.caption).foregroundStyle(Ink.muted)
            }
            Spacer(minLength: 8)
            Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(Ink.blue)
        }.padding(.vertical, 7).contentShape(Rectangle())
    }
}

struct FieldEmpty: View {
    let title: String
    let description: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.headline)
            Text(description).font(.subheadline).foregroundStyle(Ink.muted).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(15)
            .overlay { Rectangle().strokeBorder(Ink.rule, style: StrokeStyle(lineWidth: 1, dash: [4, 3])) }
    }
}

struct ActionLabel: View {
    let title: String
    let icon: String
    var fill = Ink.blue
    var color = Color.white
    var body: some View {
        HStack { Image(systemName: icon); Text(title).font(.headline); Spacer(); Image(systemName: "arrow.right") }
            .foregroundStyle(color).padding(14).background(fill)
    }
}

struct PageBody<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 19) { content }.padding(18).frame(maxWidth: 690) }
            .frame(maxWidth: .infinity).background(Ink.paper).foregroundStyle(Ink.dark)
    }
}
