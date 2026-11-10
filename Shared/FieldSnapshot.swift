import Foundation

struct PocketLabel: Codable, Identifiable {
    let id: String
    let name: String
    let brand: String
    let sugar: Double?
    let salt: Double?
    let choiceCount: Int
}

struct FieldSnapshot: Codable {
    static let group = "group.app.labelloupe.journal"
    static let key = "fieldSnapshot.v1"
    var generatedAt: Date?
    var collection = [PocketLabel]()
    var savedCount = 0
    var latest: PocketLabel?
    var latestDate: Date?
    var totalChoices = 0
}
