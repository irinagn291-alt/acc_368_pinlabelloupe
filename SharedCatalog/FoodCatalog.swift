import Foundation

struct FoodProduct: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let brand: String
    var kcal: Double?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    var fiber: Double?
    var sugar: Double?
    var salt: Double?
    var ingredients: String?
    var allergens: [String] = []
    var imageURL: URL?
}

private struct OFFNumber: Decodable {
    let value: Double?
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let numeric = (try? container.decode(Double.self)) ??
            (try? container.decode(String.self)).flatMap { Double($0.replacingOccurrences(of: ",", with: ".")) }
        value = numeric.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
    }
}

private struct OFFRecord: Decodable {
    let code, product_name_en, product_name, generic_name_en, brands, lang: String?
    let ingredients_text_en, ingredients_text, image_front_small_url: String?
    let allergens_tags: [String]?
    let nutriments: [String: OFFNumber]?

    private func firstText(_ candidates: String?...) -> String? {
        candidates.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }?
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#39;", with: "'")
    }

    var product: FoodProduct? {
        guard let code, !code.isEmpty, let name = firstText(product_name_en, generic_name_en, lang == "en" ? product_name : nil, product_name, brands) else { return nil }
        func value(_ key: String) -> Double? { nutriments?[key + "_100g"]?.value }
        return FoodProduct(id: code, name: name, brand: firstText(brands) ?? "",
                           kcal: value("energy-kcal") ?? (value("energy-kj") ?? value("energy")).map { $0 / 4.184 },
                           protein: value("proteins"), carbs: value("carbohydrates"), fat: value("fat"),
                           fiber: value("fiber"), sugar: value("sugars"), salt: value("salt"),
                           ingredients: firstText(ingredients_text_en, lang == "en" ? ingredients_text : nil),
                           allergens: allergens_tags ?? [], imageURL: image_front_small_url.flatMap { URL(string: $0) })
    }
}

private struct OFFPage: Decodable { let products: [OFFRecord] }
private struct OFFLookup: Decodable { let status: Int?; let product: OFFRecord? }

enum CatalogIssue: LocalizedError {
    case missing, busy, unexpected
    var errorDescription: String? {
        switch self {
        case .missing: return "This barcode isn’t in the catalog yet."
        case .busy: return "The catalog is limiting requests. Try again in a minute."
        case .unexpected: return "Couldn’t load the product data. Try again."
        }
    }
}

#if DEBUG && targetEnvironment(simulator)
/// Explicit launch options for isolated factory captures. Indices are one-based.
enum ScreenshotLaunch {
    static let keys = ["desk", "food-catalog", "dossier", "compare", "collection", "choice-history", "manual-entry"]
    private static let arguments = ProcessInfo.processInfo.arguments
    private static let environment = ProcessInfo.processInfo.environment

    private static func argument(_ name: String) -> String? {
        guard let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    static let enabled = arguments.contains("-ReviewScreen") || arguments.contains("-AppStoreScreenshots") ||
        ["1", "true", "yes"].contains(environment["APPSTORE_SCREENSHOTS"]?.lowercased() ?? "")
    static let screen: String = {
        if let key = argument("-ReviewScreen"), keys.contains(key) { return key }
        let rawIndex = argument("-AppStoreScreenshotScreen") ?? environment["APPSTORE_SCREENSHOT_SCREEN"]
        if let rawIndex, let index = Int(rawIndex), (1...keys.count).contains(index) { return keys[index - 1] }
        return "desk"
    }()
}
#endif

enum FoodCatalog {
    private static let cacheKey = "off.catalog.products.v1"
    private static let fields = "code,product_name_en,product_name,generic_name_en,lang,brands,ingredients_text_en,ingredients_text,allergens_tags,nutriments,image_front_small_url"
    static let bundled: [FoodProduct] = {
        guard let url = Bundle.main.url(forResource: "OfflineProducts", withExtension: "json"),
              let data = try? Data(contentsOf: url), let page = try? JSONDecoder().decode(OFFPage.self, from: data)
        else { return [] }
        return page.products.compactMap(\.product)
    }()

    #if DEBUG && targetEnvironment(simulator)
    private static var screenshotCache: [FoodProduct] = []
    #endif
    static var saved: [FoodProduct] {
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.enabled { return screenshotCache }
        #endif
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return [] }
        return (try? JSONDecoder().decode([FoodProduct].self, from: data)) ?? []
    }
    static func merge(_ first: [FoodProduct], _ second: [FoodProduct]) -> [FoodProduct] {
        var seen = Set<String>()
        return (first + second).filter { seen.insert($0.id).inserted }
    }
    static func remember(_ products: [FoodProduct]) {
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.enabled {
            screenshotCache = Array(merge(products, screenshotCache).prefix(250))
            return
        }
        #endif
        let recent = Array(merge(products, saved).prefix(250))
        if let encoded = try? JSONEncoder().encode(recent) { UserDefaults.standard.set(encoded, forKey: cacheKey) }
    }
    static func local(_ query: String, in products: [FoodProduct]) -> [FoodProduct] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty { return products }
        if let code = barcode(query) { return products.filter { $0.id == code || $0.id == query } }
        return products.filter { ($0.name + " " + $0.brand).localizedCaseInsensitiveContains(query) }
    }
    static func barcode(_ text: String) -> String? {
        let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = raw.components(separatedBy: CharacterSet(charactersIn: "0123456789").inverted)
        guard let code = parts.first(where: { (8...14).contains($0.count) }) else { return nil }
        return code.count == 12 ? "0" + code : code
    }

    static func remote(_ term: String) async throws -> [FoodProduct] {
        let code = barcode(term)
        var url = URLComponents()
        url.scheme = "https"
        url.host = "world.openfoodfacts.org"
        url.path = code.map { "/api/v2/product/\($0).json" } ?? "/cgi/search.pl"
        var parameters = [URLQueryItem(name: "fields", value: fields), URLQueryItem(name: "lc", value: "en")]
        if code == nil {
            let search = [("search_terms", term), ("search_simple", "1"), ("action", "process"),
                          ("json", "1"), ("page_size", "30")]
            parameters += search.map { URLQueryItem(name: $0.0, value: $0.1) }
        }
        url.queryItems = parameters
        guard let endpoint = url.url else { throw CatalogIssue.unexpected }
        var request = URLRequest(url: endpoint, timeoutInterval: 15)
        let name = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "FoodCatalog"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        request.setValue("\(name)/\(version) (https://github.com/flammeimherzen/gambling_factory)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CatalogIssue.unexpected }
        if http.statusCode == 404 && code != nil { throw CatalogIssue.missing }
        if http.statusCode == 429 { throw CatalogIssue.busy }
        guard (200..<300).contains(http.statusCode) else { throw CatalogIssue.unexpected }
        let decoder = JSONDecoder()
        if code != nil {
            let lookup = try decoder.decode(OFFLookup.self, from: data)
            guard lookup.status != 0, let product = lookup.product?.product else { throw CatalogIssue.missing }
            return [product]
        }
        return try decoder.decode(OFFPage.self, from: data).products.compactMap(\.product)
    }
}
