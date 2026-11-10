import Foundation
import SwiftUI
import WatchConnectivity
import WidgetKit

struct Choice: Codable, Identifiable {
    let id: UUID
    let productID: String
    let date: Date
}

struct Archive: Codable {
    var products = [String: FoodProduct]()
    var recent = [String]()
    var collection = [String]()
    var comparison: [String?] = [nil, nil]
    var choices = [Choice]()
}

final class Journal: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var archive: Archive
    @Published var writeError: String?
    private let archiveURL = URL.documentsDirectory.appending(path: "PinlabelLoupe-archive-v1.json")

    override init() {
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.enabled {
            archive = Archive()
            super.init()
            seedScreenshot()
            return
        }
        #endif
        if let data = try? Data(contentsOf: archiveURL), let stored = try? JSONDecoder().decode(Archive.self, from: data) {
            archive = stored
        } else { archive = Archive() }
        super.init()
        if WCSession.isSupported() { WCSession.default.delegate = self; WCSession.default.activate() }
        publishSnapshot()
    }

    #if DEBUG && targetEnvironment(simulator)
    private func seedScreenshot() {
        let ids = ["3017620422003", "3168930003632", "8076800105735"]
        let products = ids.compactMap { id in FoodCatalog.bundled.first { $0.id == id } }
        for product in products { inspect(product) }
        for product in products { toggleSaved(product.id) }
        if ScreenshotLaunch.screen == "choice-history" {
            for (index, product) in products.enumerated() {
                record(product.id, date: Date().addingTimeInterval(Double(-index * 86400)))
            }
        } else if let first = products.first {
            record(first.id)
        }
        if products.count >= 2 {
            compare(products[0].id, at: 0)
            compare(products[1].id, at: 1)
        }
    }
    #endif

    func inspect(_ product: FoodProduct) {
        archive.products[product.id] = product
        archive.recent.removeAll { $0 == product.id }
        archive.recent.insert(product.id, at: 0)
        archive.recent = Array(archive.recent.prefix(30))
        commit()
    }

    func toggleSaved(_ id: String) {
        if archive.collection.contains(id) { archive.collection.removeAll { $0 == id } }
        else { archive.collection.insert(id, at: 0) }
        commit()
    }

    func compare(_ id: String, at index: Int) {
        guard !archive.comparison.contains(id) else { return }
        guard (0..<2).contains(index) else { return }
        while archive.comparison.count < 2 { archive.comparison.append(nil) }
        archive.comparison[index] = id
        commit()
    }

    func clearSlot(_ id: String) {
        guard let index = archive.comparison.firstIndex(of: id) else { return }
        archive.comparison[index] = nil
        commit()
    }

    @discardableResult
    func record(_ id: String, event: UUID = UUID(), date: Date = Date()) -> Bool {
        guard archive.products[id] != nil else { return false }
        if archive.choices.contains(where: { $0.id == event }) { return true }
        archive.choices.append(Choice(id: event, productID: id, date: date))
        archive.choices.sort { $0.date > $1.date }
        if commit() { return true }
        archive.choices.removeAll { $0.id == event }
        return false
    }

    func removeEvent(_ event: UUID) { archive.choices.removeAll { $0.id == event }; commit() }

    @discardableResult
    private func commit() -> Bool {
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.enabled { return true }
        #endif
        do {
            try JSONEncoder().encode(archive).write(to: archiveURL, options: .atomic)
            publishSnapshot()
            return true
        } catch {
            writeError = "This device could not save your changes."
            return false
        }
    }

    private func pocket(_ id: String) -> PocketLabel? {
        guard let p = archive.products[id] else { return nil }
        return PocketLabel(id: p.id, name: String(p.name.prefix(120)), brand: String(p.brand.prefix(60)), sugar: p.sugar, salt: p.salt, choiceCount: archive.choices.filter { $0.productID == id }.count)
    }

    private func snapshotData() -> Data? {
        var snap = FieldSnapshot()
        snap.generatedAt = Date()
        snap.collection = archive.collection.prefix(30).compactMap(pocket)
        snap.savedCount = archive.collection.count
        snap.latest = archive.choices.first.flatMap { pocket($0.productID) }
        snap.latestDate = archive.choices.first?.date
        snap.totalChoices = archive.choices.count
        return try? JSONEncoder().encode(snap)
    }

    private func publishSnapshot() {
        guard let data = snapshotData() else { return }
        UserDefaults(suiteName: FieldSnapshot.group)?.set(data, forKey: FieldSnapshot.key)
        WidgetCenter.shared.reloadTimelines(ofKind: "LabelLoupeField")
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let packet = [FieldSnapshot.key: data]
        if session.isPaired, session.isWatchAppInstalled {
            try? session.updateApplicationContext(packet)
        }
        if session.isReachable { session.sendMessage(packet, replyHandler: nil, errorHandler: nil) }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { DispatchQueue.main.async { self.publishSnapshot() } }
    func sessionWatchStateDidChange(_ session: WCSession) { DispatchQueue.main.async { self.publishSnapshot() } }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    private func receiveChoice(_ packet: [String: Any]) -> Bool {
        guard let id = packet["product"] as? String, let event = packet["event"] as? String,
              let uuid = UUID(uuidString: event), let date = packet["date"] as? Date else { return false }
        return record(id, event: uuid, date: date)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        DispatchQueue.main.async { _ = self.receiveChoice(userInfo) }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            var reply: [String: Any] = [:]
            if message["event"] != nil { reply["recorded"] = self.receiveChoice(message) }
            if let data = self.snapshotData() { reply[FieldSnapshot.key] = data }
            replyHandler(reply)
        }
    }
}
