import SwiftUI
import WidgetKit

struct FieldEntry: TimelineEntry {
    let date: Date
    let snapshot: FieldSnapshot
}
struct FieldProvider: TimelineProvider {
    private func entry() -> FieldEntry {
        let data = UserDefaults(suiteName: FieldSnapshot.group)?.data(forKey: FieldSnapshot.key)
        let snapshot = data.flatMap { try? JSONDecoder().decode(FieldSnapshot.self, from: $0) } ?? FieldSnapshot()
        return FieldEntry(date: Date(), snapshot: snapshot)
    }
    func placeholder(in context: Context) -> FieldEntry { FieldEntry(date: Date(), snapshot: FieldSnapshot()) }
    func getSnapshot(in context: Context, completion: @escaping (FieldEntry) -> Void) { completion(entry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<FieldEntry>) -> Void) {
        completion(Timeline(entries: [entry()], policy: .never))
    }
}

struct FieldWidgetView: View {
    let entry: FieldEntry
    @Environment(\.widgetFamily) private var family
    private let lemon = Color(red: 0.94, green: 0.97, blue: 0.55)
    var body: some View {
        let s = entry.snapshot
        VStack(alignment: .leading, spacing: 5) {
            Label("LABELLOUPE", systemImage: "scope").font(.caption2.monospaced().bold()).foregroundStyle(lemon)
            Spacer()
            if let p = s.latest {
                Text("Latest choice").font(.caption2)
                Text(p.name).font(.system(.headline, design: .serif)).lineLimit(2)
                if family == .systemMedium, let date = s.latestDate { Text(date.formatted(.dateTime.locale(Locale(identifier: "en_US")).day().month().hour().minute())).font(.caption) }
            } else {
                Text("Field archive").font(.system(.title2, design: .serif).bold())
                Text("Log a choice from an open label.").font(.caption)
            }
            Spacer()
            HStack(spacing: 8) { Label("\(s.savedCount)", systemImage: "bookmark"); Label("\(s.totalChoices)", systemImage: "checkmark.seal") }.font(.caption.monospacedDigit()).foregroundStyle(lemon)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .foregroundStyle(.white).containerBackground(Color(red: 0.09, green: 0.21, blue: 0.72), for: .widget)
        .widgetURL(s.latest.flatMap { URL(string: "labelloupe://detail/")?.appendingPathComponent($0.id) } ?? URL(string: "labelloupe://archive"))
    }
}
@main
struct FieldWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LabelLoupeField", provider: FieldProvider()) { FieldWidgetView(entry: $0) }
            .configurationDisplayName("PinlabelLoupe archive").description("Your latest choice and collection size.").supportedFamilies([.systemSmall, .systemMedium])
    }
}
