import SwiftUI
import WatchConnectivity

final class Pocket: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var snap: FieldSnapshot
    @Published var receipt: String?
    override init() {
        snap = UserDefaults.standard.data(forKey: FieldSnapshot.key).flatMap { try? JSONDecoder().decode(FieldSnapshot.self, from: $0) } ?? FieldSnapshot()
        super.init()
        if WCSession.isSupported() { WCSession.default.delegate = self; WCSession.default.activate() }
    }
    func log(_ product: PocketLabel) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else {
            receipt = "Your watch is still connecting. Try again in a moment."
            return
        }
        let packet: [String: Any] = ["product": product.id, "event": UUID().uuidString, "date": Date()]
        let session = WCSession.default
        guard session.isReachable else { queueChoice(packet, on: session); return }
        session.sendMessage(packet) { reply in
            self.receive(reply)
            DispatchQueue.main.async {
                self.receipt = reply["recorded"] as? Bool == true ? "Choice saved to your history." : "Your iPhone could not save this choice. Try again."
            }
        } errorHandler: { _ in self.queueChoice(packet, on: session) }
    }

    private func queueChoice(_ packet: [String: Any], on session: WCSession) {
        session.transferUserInfo(packet)
        DispatchQueue.main.async { self.receipt = "Choice queued. It will appear in history when your iPhone reconnects." }
    }

    func requestSnapshot(_ session: WCSession = .default) {
        guard session.activationState == .activated, session.isReachable else { return }
        session.sendMessage(["request": "snapshot"], replyHandler: receive, errorHandler: nil)
    }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) { receive(applicationContext) }
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) { receive(message) }
    func sessionReachabilityDidChange(_ session: WCSession) { requestSnapshot(session) }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        receive(session.receivedApplicationContext)
        requestSnapshot(session)
    }
    private func receive(_ context: [String: Any]) {
        guard let data = context[FieldSnapshot.key] as? Data, let snap = try? JSONDecoder().decode(FieldSnapshot.self, from: data) else { return }
        DispatchQueue.main.async {
            guard (snap.generatedAt ?? .distantPast) >= (self.snap.generatedAt ?? .distantPast) else { return }
            UserDefaults.standard.set(data, forKey: FieldSnapshot.key)
            self.snap = snap
        }
    }
}

@main
struct LabelLoupeWatch: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var pocket = Pocket()
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                List {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("LABEL BUREAU", systemImage: "scope").font(.caption2.monospaced()).foregroundStyle(.yellow)
                        Text("Collection").font(.system(.title2, design: .serif).bold())
                        Text("Saved: \(pocket.snap.savedCount) · Choices: \(pocket.snap.totalChoices)").font(.caption2)
                    }
                    if pocket.snap.collection.isEmpty {
                        Text("Save a label to your collection on iPhone. It will appear here after syncing.").font(.footnote)
                        Button("Refresh from iPhone") { pocket.requestSnapshot() }
                    } else {
                        ForEach(pocket.snap.collection) { p in
                            NavigationLink {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(p.name).font(.system(.headline, design: .serif))
                                        if !p.brand.isEmpty { Text(p.brand).font(.caption) }
                                        Text("PER 100 G").font(.caption2.monospaced()).foregroundStyle(.yellow)
                                        Text("Sugars: \(amount(p.sugar))"); Text("Salt: \(amount(p.salt))")
                                        Text("Choices: \(p.choiceCount)").font(.caption2)
                                        Button("Log a choice") { pocket.log(p) }.buttonStyle(.borderedProminent).tint(.blue)
                                    }.frame(maxWidth: .infinity, alignment: .leading)
                                }
                            } label: { Text(p.name) }
                        }
                    }
                }.navigationTitle("PinlabelLoupe")
            }.alert("History", isPresented: Binding(get: { pocket.receipt != nil }, set: { if !$0 { pocket.receipt = nil } })) {
                Button("Done") { pocket.receipt = nil }
            } message: { Text(pocket.receipt ?? "") }
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                pocket.requestSnapshot()
                do { try await Task.sleep(for: .seconds(3)) } catch { return }
                pocket.requestSnapshot()
            }
        }
    }
    private func amount(_ value: Double?) -> String {
        value.map { $0.formatted(.number.locale(Locale(identifier: "en_US")).precision(.fractionLength(0...2))) + " g" } ?? "unlisted"
    }
}
