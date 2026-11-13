import SwiftUI

@main
struct LabelLoupeApp: App {
    @StateObject private var launch = AppLaunch()
    @StateObject private var journal = Journal()
    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG && targetEnvironment(simulator)
                if ScreenshotLaunch.enabled {
                    nativeRoot
                } else {
                    normalRoot
                }
                #else
                normalRoot
                #endif
            }
        }
    }

    private var normalRoot: some View {
        Group {
            switch launch.mode {
            case .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .webContent:
                if let url = launch.contentURL { InAppBrowser(url: url) }
                else { nativeRoot }
            case .nativeInterface:
                nativeRoot
            }
        }
        .task { launch.start() }
    }

    private var nativeRoot: some View {
        FieldDesk().environmentObject(journal).preferredColorScheme(.light).tint(Ink.blue)
    }
}

private enum DeskPage { case desk, compare, archive }
private enum PickJob: Identifiable {
    case detail, slot(Int)
    var id: String { switch self { case .detail: return "detail"; case .slot(let n): return "slot-\(n)" } }
}

struct FieldDesk: View {
    @EnvironmentObject private var journal: Journal
    @State private var page = DeskPage.desk
    @State private var detailPath: [String] = []
    @State private var archivePath: [String] = []
    @State private var picker: PickJob?
    @State private var problem: String?
    @State private var showHistory = false
    #if DEBUG && targetEnvironment(simulator)
    init() {
        guard ScreenshotLaunch.enabled else { return }
        switch ScreenshotLaunch.screen {
        case "food-catalog", "manual-entry":
            _picker = State(initialValue: .detail)
        case "dossier":
            _detailPath = State(initialValue: ["3017620422003"])
        case "compare":
            _page = State(initialValue: .compare)
        case "collection":
            _page = State(initialValue: .archive)
        case "choice-history":
            _page = State(initialValue: .archive)
            _showHistory = State(initialValue: true)
        default: break
        }
    }
    #endif

    var body: some View {
        TabView(selection: $page) {
            NavigationStack(path: $detailPath) {
                bench.navigationDestination(for: String.self) { id in dossier(id) }
            }.tabItem { Label("Desk", systemImage: "viewfinder") }.tag(DeskPage.desk)
            NavigationStack {
                ComparisonView { picker = .slot($0) }
            }.tabItem { Label("Compare", systemImage: "rectangle.split.2x1") }.tag(DeskPage.compare)
            NavigationStack(path: $archivePath) {
                ArchiveView(showHistory: $showHistory).navigationDestination(for: String.self) { id in dossier(id) }
            }.tabItem { Label("Archive", systemImage: "tray.full") }.tag(DeskPage.archive)
        }
        .sheet(item: $picker) { job in
            FoodCatalogPicker { p in
                journal.inspect(p)
                switch job {
                case .detail: page = .desk; detailPath = [p.id]
                case .slot(let i): if journal.archive.comparison.contains(p.id) { problem = "This label is already on the comparison table." } else { journal.compare(p.id, at: i) }
                }
            }
        }
        .alert("PinlabelLoupe", isPresented: Binding(get: { problem != nil || journal.writeError != nil }, set: { if !$0 { problem = nil; journal.writeError = nil } })) {
            Button("Close", role: .cancel) { problem = nil; journal.writeError = nil }
        } message: { Text(problem ?? journal.writeError ?? "") }
        .onOpenURL { url in
            guard url.scheme == "labelloupe" else { return }
            if url.host == "detail", let id = url.pathComponents.last, journal.archive.products[id] != nil { page = .desk; detailPath = [id] }
            else { archivePath = []; showHistory = url.host == "history"; page = .archive }
        }
        #if DEBUG && targetEnvironment(simulator)
        .transaction { transaction in
            if ScreenshotLaunch.enabled { transaction.animation = nil; transaction.disablesAnimations = true }
        }
        #endif
    }

    @ViewBuilder private func dossier(_ id: String) -> some View {
        if let p = journal.archive.products[id] {
            DossierView(product: p) {
                if !journal.archive.comparison.contains(id), let slot = journal.archive.comparison.firstIndex(of: nil) { journal.compare(id, at: slot) }
                page = .compare
            }
        }
    }

    private var bench: some View {
        PageBody {
            HStack {
                Image(systemName: "scope").foregroundStyle(Ink.blue)
                IndexTag(text: "PinlabelLoupe  /  label bureau")
                Spacer()
                Text("01—03").font(.caption.monospaced())
            }
            Divider()
            FieldHeading(index: "01   /   FIELDWORK", title: "The lab")
            VStack(alignment: .leading, spacing: 12) {
                IndexTag(text: "FIELD STUDY     ·     LL—01").foregroundStyle(Ink.lemon)
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Under the lens").font(.system(.largeTitle, design: .serif).italic()).foregroundStyle(.white)
                        Text("Read the ingredients, check allergens and compare nutrients per 100 g.").font(.subheadline).foregroundStyle(.white.opacity(0.94))
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    SpecimenSeal().frame(width: 82, height: 88)
                }
                Button { picker = .detail } label: { ActionLabel(title: "Find a label", icon: "viewfinder", fill: Ink.lemon, color: Ink.dark) }.accessibilityIdentifier("desk.find")
            }.padding(17).background(Ink.blue)
            HStack(spacing: 9) {
                Button { page = .archive; showHistory = false } label: { counter(journal.archive.collection.count, "Saved", "bookmark") }
                Button { page = .archive; showHistory = true } label: { counter(journal.archive.choices.count, "Choices", "checkmark.seal") }
            }
            HStack { IndexTag(text: "On the desk"); Spacer(); Text("recent dossiers").foregroundStyle(Ink.muted).font(.caption) }
            if journal.archive.recent.isEmpty {
                FieldEmpty(title: "A fresh desk", description: "Look up a name or scan a barcode. The labels you open will stay here.")
            } else {
                ForEach(journal.archive.recent.prefix(6), id: \.self) { id in
                    if let p = journal.archive.products[id] { NavigationLink(value: id) { ProductLine(product: p) }; Divider() }
                }
            }
        }.buttonStyle(.plain).toolbar(.hidden, for: .navigationBar)
    }

    private func counter(_ n: Int, _ label: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack { Image(systemName: icon).foregroundStyle(Ink.blue); Spacer(); Text(String(format: "%02d", n)).font(.title2.monospacedDigit().bold()) }
            Text(label).font(.caption)
        }.padding(12).background(Ink.white).overlay { Rectangle().strokeBorder(Ink.rule) }
    }
}
